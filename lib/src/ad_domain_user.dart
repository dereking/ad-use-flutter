class AdDomainUser {
  const AdDomainUser({
    required this.distinguishedName,
    required this.username,
    required this.email,
    required this.displayName,
    this.userPrincipalName,
    this.commonName,
    this.department,
    this.title,
    this.telephoneNumber,
    this.mobile,
    this.memberOf = const [],
    this.managerDn,
    this.objectGuid,
    this.attributes = const {},
  });

  final String distinguishedName;
  final String username;
  final String email;
  final String displayName;
  final String? userPrincipalName;
  final String? commonName;
  final String? department;
  final String? title;
  final String? telephoneNumber;
  final String? mobile;
  final List<String> memberOf;
  final String? managerDn;
  final String? objectGuid;
  final Map<String, List<String>> attributes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdDomainUser &&
          distinguishedName == other.distinguishedName &&
          username == other.username &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(
        distinguishedName,
        username,
        email,
        displayName,
      );
}
