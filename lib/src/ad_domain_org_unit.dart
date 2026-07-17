import 'ad_domain_user.dart';

class AdDomainOrgUnit {
  const AdDomainOrgUnit({
    required this.name,
    this.distinguishedName,
    this.children = const [],
    this.users = const [],
  });

  final String name;
  final String? distinguishedName;
  final List<AdDomainOrgUnit> children;
  final List<AdDomainUser> users;
}
