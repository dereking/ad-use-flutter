import 'ad_domain_user.dart';

abstract class AdDomainDirectoryAdapter {
  Future<bool> authenticate(String username, String password);

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
