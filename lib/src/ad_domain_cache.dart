import 'ad_domain_org_unit.dart';
import 'ad_domain_user.dart';

class AdDomainCache {
  AdDomainCache({
    required this.ttl,
    required this.maxUsers,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration ttl;
  final int maxUsers;
  final DateTime Function() _now;

  final Map<String, _CacheEntry<AdDomainUser>> _usersByEmail = {};
  final Map<String, _CacheEntry<AdDomainUser>> _usersByUsername = {};
  final Map<String, _CacheEntry<List<AdDomainUser>>> _usersByName = {};
  _CacheEntry<List<AdDomainOrgUnit>>? _organizationTree;

  AdDomainUser? getUserByEmail(String email) =>
      _read(_usersByEmail[_normalize(email)]);

  AdDomainUser? getUserByUsername(String username) =>
      _read(_usersByUsername[_normalize(username)]);

  List<AdDomainUser>? getUsersByName(String name) =>
      _read(_usersByName[_normalize(name)]);

  List<AdDomainOrgUnit>? get organizationTree => _read(_organizationTree);

  void storeUser(AdDomainUser user) {
    if (_usersByEmail.length >= maxUsers &&
        !_usersByEmail.containsKey(user.email)) {
      clear();
    }

    final entry = _CacheEntry(user, _now().add(ttl));
    if (user.email.isNotEmpty) {
      _usersByEmail[_normalize(user.email)] = entry;
    }
    if (user.username.isNotEmpty) {
      _usersByUsername[_normalize(user.username)] = entry;
    }
  }

  void storeUsersByName(String name, List<AdDomainUser> users) {
    final expiresAt = _now().add(ttl);
    _usersByName[_normalize(name)] =
        _CacheEntry(List.unmodifiable(users), expiresAt);
    for (final user in users) {
      storeUser(user);
    }
  }

  void storeOrganizationTree(List<AdDomainOrgUnit> tree) {
    _organizationTree = _CacheEntry(List.unmodifiable(tree), _now().add(ttl));
  }

  void clear() {
    _usersByEmail.clear();
    _usersByUsername.clear();
    _usersByName.clear();
    _organizationTree = null;
  }

  T? _read<T>(_CacheEntry<T>? entry) {
    if (entry == null) return null;
    if (_now().isAfter(entry.expiresAt)) return null;
    return entry.value;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;
}
