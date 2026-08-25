import 'package:asn1lib/asn1lib.dart';
import 'package:dartdap/dartdap.dart';

import 'ad_domain_auth_result.dart';
import 'ad_domain_config.dart';
import 'ad_domain_directory_adapter.dart';
import 'ad_domain_user.dart';

class LdapAdDomainDirectoryAdapter implements AdDomainDirectoryAdapter {
  LdapAdDomainDirectoryAdapter(this.config);

  final AdDomainConfig config;

  @override
  Future<bool> authenticate(String username, String password) async {
    return (await validateUser(username, password)).success;
  }

  @override
  Future<AdDomainAuthResult> validateUser(
    String username,
    String password,
  ) async {
    final normalized = username.trim();
    if (normalized.isEmpty || password.isEmpty) {
      return const AdDomainAuthResult.invalidCredentials('账号或密码不能为空');
    }
    final bindName = _userBindName(normalized);
    return _bind(bindName, password, rawBindName: true);
  }

  @override
  Future<AdDomainAuthResult> testConnection() {
    return _bind(config.bindDn, config.bindPassword);
  }

  /// 用户绑定名：已是 UPN（含 `@`）则原样使用，否则拼成 `用户名@userDomain`。
  String _userBindName(String username) {
    if (username.contains('@')) return username;
    final domain = config.userDomain;
    if (domain == null || domain.trim().isEmpty) return username;
    return '$username@$domain';
  }

  /// 打开连接并绑定 [bindDn]；区分「无法连接」与「账号/密码错误」。
  Future<AdDomainAuthResult> _bind(
    String bindDn,
    String password, {
    bool rawBindName = false,
  }) async {
    final connection = _createConnection(
      bindDn: bindDn,
      password: password,
      rawBindName: rawBindName,
    );
    try {
      await connection.open();
    } catch (e) {
      return AdDomainAuthResult.unreachable('无法连接 AD 服务器：$e');
    }
    try {
      final result = await connection.bind();
      return result.resultCode == ResultCode.OK
          ? const AdDomainAuthResult.success()
          : const AdDomainAuthResult.invalidCredentials();
    } catch (_) {
      return const AdDomainAuthResult.invalidCredentials('账号或密码错误');
    } finally {
      try {
        await connection.close();
      } catch (_) {}
    }
  }

  @override
  Future<AdDomainUser?> getUserByEmail(String email) async {
    final users = await _searchUsers(
      '(&${_userClassFilter()}(${config.emailAttribute}=${_escapeFilterValue(email)}))',
      sizeLimit: 1,
    );
    return users.firstOrNull;
  }

  @override
  Future<AdDomainUser?> getUserByUsername(String username) async {
    final escaped = _escapeFilterValue(username);
    final users = await _searchUsers(
      '(&${_userClassFilter()}(|'
      '(${config.usernameAttribute}=$escaped)'
      '(${config.userPrincipalNameAttribute}=$escaped)'
      '))',
      sizeLimit: 1,
    );
    return users.firstOrNull;
  }

  @override
  Future<List<AdDomainUser>> searchUsersByName(String name) {
    final escaped = _escapeFilterValue(name);
    return _searchUsers(
      '(&${_userClassFilter()}(|'
      '(${config.displayNameAttribute}=*$escaped*)'
      '(${config.commonNameAttribute}=*$escaped*)'
      '))',
      sizeLimit: config.searchSizeLimit,
    );
  }

  @override
  Future<List<AdDomainUser>> searchUsersByEmailPrefix(String emailPrefix) {
    final escaped = _escapeFilterValue(emailPrefix);
    return _searchUsers(
      '(&${_userClassFilter()}(|'
      '(${config.emailAttribute}=$escaped*)'
      '(${config.userPrincipalNameAttribute}=$escaped*)'
      '))',
      sizeLimit: config.searchSizeLimit,
    );
  }

  @override
  Future<List<AdDomainUser>> searchUsersByDisplayName(String name) {
    final escaped = _escapeFilterValue(name);
    return _searchUsers(
      '(&${_userClassFilter()}(${config.displayNameAttribute}=*$escaped*))',
      sizeLimit: config.searchSizeLimit,
    );
  }

  @override
  Future<List<AdDomainUser>> searchUsersByUsernamePrefix(String usernamePrefix) {
    final escaped = _escapeFilterValue(usernamePrefix);
    return _searchUsers(
      '(&${_userClassFilter()}(|'
      '(${config.usernameAttribute}=$escaped*)'
      '(${config.userPrincipalNameAttribute}=$escaped*)'
      '))',
      sizeLimit: config.searchSizeLimit,
    );
  }

  @override
  Future<List<AdDomainUser>> getAllUsers() {
    return _searchUsers(
      '(&${_userClassFilter()}(${config.emailAttribute}=*))',
      sizeLimit: 0,
    );
  }

  Future<List<AdDomainUser>> _searchUsers(
    String filter, {
    required int sizeLimit,
  }) async {
    final connection = _createConnection(
      bindDn: config.bindDn,
      password: config.bindPassword,
    );

    try {
      await connection.open();
      await connection.bind();

      final result = await connection.query(
        DN(config.baseDn),
        filter,
        ['dn', ...config.userAttributes],
        sizeLimit: sizeLimit,
      );
      final users = <AdDomainUser>[];
      await for (final entry in result.stream) {
        // 跳过目录分区引用（referral）条目，例如 Configuration /
        // DomainDnsZones / ForestDnsZones，它们没有真实用户属性。
        if (entry.hasReferrals) continue;
        users.add(_mapEntry(entry));
      }
      return users;
    } finally {
      await connection.close();
    }
  }

  LdapConnection _createConnection({
    required String bindDn,
    required String password,
    bool rawBindName = false,
  }) {
    return LdapConnection(
      host: config.host,
      port: config.port,
      ssl: config.useSsl,
      bindDN: rawBindName
          ? DN.fromOctetString(ASN1OctetString(bindDn))
          : DN(bindDn),
      password: password,
    );
  }

  AdDomainUser _mapEntry(SearchEntry entry) {
    final attributes = _stringAttributes(entry);
    final email = _first(attributes, config.emailAttribute) ?? '';
    final username = _first(attributes, config.usernameAttribute) ??
        _first(attributes, config.userPrincipalNameAttribute) ??
        email;
    final displayName = _first(attributes, config.displayNameAttribute) ??
        _first(attributes, config.commonNameAttribute) ??
        username;

    return AdDomainUser(
      distinguishedName: entry.dn.toString(),
      username: username,
      email: email,
      displayName: displayName,
      userPrincipalName: _first(attributes, config.userPrincipalNameAttribute),
      commonName: _first(attributes, config.commonNameAttribute),
      department: _first(attributes, config.departmentAttribute),
      title: _first(attributes, config.titleAttribute),
      telephoneNumber: _first(attributes, config.telephoneAttribute),
      mobile: _first(attributes, config.mobileAttribute),
      memberOf: _all(attributes, config.memberOfAttribute),
      managerDn: _first(attributes, config.managerAttribute),
      objectGuid: _first(attributes, config.objectGuidAttribute),
      attributes: attributes,
    );
  }

  Map<String, List<String>> _stringAttributes(SearchEntry entry) {
    final result = <String, List<String>>{};
    for (final ldapAttribute in entry.attributes.values) {
      result[ldapAttribute.name] =
          ldapAttribute.values.map(_valueToString).toList();
    }
    return result;
  }

  String _valueToString(Object value) {
    if (value is ASN1OctetString) {
      return value.toString();
    }
    return value.toString();
  }

  String? _first(Map<String, List<String>> attributes, String name) {
    final values = _all(attributes, name);
    return values.isEmpty ? null : values.first;
  }

  List<String> _all(Map<String, List<String>> attributes, String name) {
    final entry = attributes.entries
        .where((entry) => entry.key.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    return entry == null ? const [] : List.unmodifiable(entry.value);
  }

  String _userClassFilter() {
    return '(objectClass=${_escapeFilterValue(config.userObjectClass)})';
  }

  String _escapeFilterValue(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      switch (codeUnit) {
        case 0x00:
          buffer.write(r'\00');
        case 0x28:
          buffer.write(r'\28');
        case 0x29:
          buffer.write(r'\29');
        case 0x2a:
          buffer.write(r'\2a');
        case 0x5c:
          buffer.write(r'\5c');
        default:
          buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
