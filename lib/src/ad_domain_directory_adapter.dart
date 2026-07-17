import 'ad_domain_user.dart';

abstract class AdDomainDirectoryAdapter {
  Future<bool> authenticate(String username, String password);

  Future<AdDomainUser?> getUserByEmail(String email);

  Future<AdDomainUser?> getUserByUsername(String username);

  Future<List<AdDomainUser>> searchUsersByName(String name);

  Future<List<AdDomainUser>> getAllUsers();
}
