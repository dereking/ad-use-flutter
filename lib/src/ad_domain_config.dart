enum AdOrganizationTreeMode {
  ou,
  department,
}

class AdDomainConfig {
  const AdDomainConfig({
    required this.host,
    required this.bindDn,
    required this.bindPassword,
    required this.baseDn,
    this.port = 389,
    this.useSsl = false,
    this.userObjectClass = 'user',
    this.emailAttribute = 'mail',
    this.usernameAttribute = 'sAMAccountName',
    this.userPrincipalNameAttribute = 'userPrincipalName',
    this.displayNameAttribute = 'displayName',
    this.commonNameAttribute = 'cn',
    this.departmentAttribute = 'department',
    this.titleAttribute = 'title',
    this.telephoneAttribute = 'telephoneNumber',
    this.mobileAttribute = 'mobile',
    this.memberOfAttribute = 'memberOf',
    this.managerAttribute = 'manager',
    this.objectGuidAttribute = 'objectGUID',
    this.organizationTreeMode = AdOrganizationTreeMode.ou,
    this.cacheTtl = const Duration(minutes: 30),
    this.maxCachedUsers = 1000,
    this.searchSizeLimit = 100,
    this.userDomain,
  });

  final String host;
  final int port;
  final bool useSsl;
  final String bindDn;
  final String bindPassword;
  final String baseDn;

  final String userObjectClass;
  final String emailAttribute;
  final String usernameAttribute;
  final String userPrincipalNameAttribute;
  final String displayNameAttribute;
  final String commonNameAttribute;
  final String departmentAttribute;
  final String titleAttribute;
  final String telephoneAttribute;
  final String mobileAttribute;
  final String memberOfAttribute;
  final String managerAttribute;
  final String objectGuidAttribute;

  final AdOrganizationTreeMode organizationTreeMode;
  final Duration cacheTtl;
  final int maxCachedUsers;
  final int searchSizeLimit;

  /// 用户所属域（如 `it2004.gree.com.cn`），用于直接 bind 校验时构造
  /// `用户名@域` 形式的绑定名；为空时直接用用户名绑定。
  final String? userDomain;

  List<String> get userAttributes => [
        emailAttribute,
        usernameAttribute,
        userPrincipalNameAttribute,
        displayNameAttribute,
        commonNameAttribute,
        departmentAttribute,
        titleAttribute,
        telephoneAttribute,
        mobileAttribute,
        memberOfAttribute,
        managerAttribute,
        objectGuidAttribute,
      ];
}
