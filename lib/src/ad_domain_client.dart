import 'ad_domain_cache.dart';
import 'ad_domain_config.dart';
import 'ad_domain_directory_adapter.dart';
import 'ad_domain_org_unit.dart';
import 'ad_domain_user.dart';
import 'ldap_ad_domain_directory_adapter.dart';

class AdDomainClient {
  AdDomainClient({
    required this.config,
    AdDomainDirectoryAdapter? adapter,
    AdDomainCache? cache,
  })  : _adapter = adapter ?? LdapAdDomainDirectoryAdapter(config),
        _cache = cache ??
            AdDomainCache(
              ttl: config.cacheTtl,
              maxUsers: config.maxCachedUsers,
            );

  final AdDomainConfig config;
  final AdDomainDirectoryAdapter _adapter;
  final AdDomainCache _cache;

  Future<bool> authenticate(String username, String password) {
    return _adapter.authenticate(username, password);
  }

  Future<AdDomainUser?> getUserByEmail(String email) async {
    final cached = _cache.getUserByEmail(email);
    if (cached != null) return cached;

    final user = await _adapter.getUserByEmail(email);
    if (user != null) _cache.storeUser(user);
    return user;
  }

  Future<AdDomainUser?> getUserByUsername(String username) async {
    final cached = _cache.getUserByUsername(username);
    if (cached != null) return cached;

    final user = await _adapter.getUserByUsername(username);
    if (user != null) _cache.storeUser(user);
    return user;
  }

  Future<List<AdDomainUser>> searchUsersByName(String name) async {
    final cached = _cache.getUsersByName(name);
    if (cached != null) return cached;

    final users = await _adapter.searchUsersByName(name);
    _cache.storeUsersByName(name, users);
    return users;
  }

  /// Queries AD users by the email-address prefix (the domain username, i.e.
  /// the part before `@`). Returns user details including organization.
  Future<List<AdDomainUser>> searchUsersByEmailPrefix(String emailPrefix) async {
    final normalized = emailPrefix.trim();
    if (normalized.isEmpty) return const [];

    final cached = _cache.getUsersByEmailPrefix(normalized);
    if (cached != null) return cached;

    final users = await _adapter.searchUsersByEmailPrefix(normalized);
    _cache.storeUsersByEmailPrefix(normalized, users);
    return users;
  }

  /// Queries AD users whose display name contains [name] (fuzzy match).
  Future<List<AdDomainUser>> searchUsersByDisplayName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return const [];

    final cached = _cache.getUsersByDisplayName(normalized);
    if (cached != null) return cached;

    final users = await _adapter.searchUsersByDisplayName(normalized);
    _cache.storeUsersByDisplayName(normalized, users);
    return users;
  }

  /// Queries AD users whose domain username (sAMAccountName / UPN prefix)
  /// starts with [usernamePrefix].
  Future<List<AdDomainUser>> searchUsersByUsernamePrefix(
      String usernamePrefix) async {
    final normalized = usernamePrefix.trim();
    if (normalized.isEmpty) return const [];

    final cached = _cache.getUsersByUsernamePrefix(normalized);
    if (cached != null) return cached;

    final users = await _adapter.searchUsersByUsernamePrefix(normalized);
    _cache.storeUsersByUsernamePrefix(normalized, users);
    return users;
  }

  Future<List<AdDomainOrgUnit>> getOrganizationTree() async {
    final cached = _cache.organizationTree;
    if (cached != null) return cached;

    final users = await _adapter.getAllUsers();
    for (final user in users) {
      _cache.storeUser(user);
    }
    final tree = buildOrganizationTree(
      users,
      mode: config.organizationTreeMode,
    );
    _cache.storeOrganizationTree(tree);
    return tree;
  }

  Future<void> warmUpCache() async {
    final users = await _adapter.getAllUsers();
    for (final user in users) {
      _cache.storeUser(user);
    }
    _cache.storeOrganizationTree(
      buildOrganizationTree(users, mode: config.organizationTreeMode),
    );
  }

  Future<void> clearCache() async {
    _cache.clear();
  }
}

List<AdDomainOrgUnit> buildOrganizationTree(
  List<AdDomainUser> users, {
  required AdOrganizationTreeMode mode,
}) {
  final root = _MutableOrgNode('');
  for (final user in users) {
    final path = switch (mode) {
      AdOrganizationTreeMode.ou => _ouPathFromDn(user.distinguishedName),
      AdOrganizationTreeMode.department => _departmentPath(user.department),
    };
    _insertUser(root, path, user);
  }
  return _freezeChildren(root);
}

void _insertUser(_MutableOrgNode root, List<String> path, AdDomainUser user) {
  var current = root;
  final effectivePath = path.isEmpty ? const ['Users'] : path;
  for (final segment in effectivePath) {
    current =
        current.children.putIfAbsent(segment, () => _MutableOrgNode(segment));
  }
  current.users.add(user);
}

List<String> _ouPathFromDn(String distinguishedName) {
  final parts = distinguishedName
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.toUpperCase().startsWith('OU='))
      .map((part) => part.substring(3))
      .toList();
  return parts.reversed.toList();
}

List<String> _departmentPath(String? department) {
  if (department == null || department.trim().isEmpty) return const [];
  return department
      .split(RegExp(r'[/\\>]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

List<AdDomainOrgUnit> _freezeChildren(_MutableOrgNode node) {
  return node.children.values
      .map(
        (child) => AdDomainOrgUnit(
          name: child.name,
          children: _freezeChildren(child),
          users: List.unmodifiable(child.users),
        ),
      )
      .toList(growable: false);
}

class _MutableOrgNode {
  _MutableOrgNode(this.name);

  final String name;
  final Map<String, _MutableOrgNode> children = {};
  final List<AdDomainUser> users = [];
}
