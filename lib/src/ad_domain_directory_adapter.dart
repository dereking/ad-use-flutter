import 'ad_domain_auth_result.dart';
import 'ad_domain_user.dart';

abstract class AdDomainDirectoryAdapter {
  Future<bool> authenticate(String username, String password);

  /// 校验域账号 + 密码：以 `用户名@userDomain`（或用户名本身）直接做 LDAP
  /// bind，无需服务账号预搜索。
  Future<AdDomainAuthResult> validateUser(String username, String password);

  /// 用配置中的 bind 账号（bindDn/bindPassword）连接并绑定服务器，
  /// 用于 AD 域设置保存时校验连接是否可用。
  Future<AdDomainAuthResult> testConnection();

  Future<AdDomainUser?> getUserByEmail(String email);

  Future<AdDomainUser?> getUserByUsername(String username);

  Future<List<AdDomainUser>> searchUsersByName(String name);

  /// Queries AD users whose email address (or UPN/domain username prefix)
  /// starts with [prefix]/[emailPrefix]. The prefix is the part before the
  /// `@` in an email address (the domain username).
  Future<List<AdDomainUser>> searchUsersByEmailPrefix(String emailPrefix);

  /// Queries AD users whose display name contains [name] (fuzzy match).
  Future<List<AdDomainUser>> searchUsersByDisplayName(String name);

  /// Queries AD users whose domain username (sAMAccountName / UPN) starts
  /// with [usernamePrefix], returning their details including organization.
  Future<List<AdDomainUser>> searchUsersByUsernamePrefix(String usernamePrefix);

  Future<List<AdDomainUser>> getAllUsers();
}
