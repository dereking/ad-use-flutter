class AdDomainSettingsValue {
  const AdDomainSettingsValue({
    this.enabled = false,
    this.host = '',
    this.port,
    this.useSsl = false,
    this.baseDn = '',
    this.bindDn = '',
    this.bindPassword = '',
  });

  final bool enabled;
  final String host;
  final int? port;
  final bool useSsl;
  final String baseDn;
  final String bindDn;
  final String bindPassword;

  AdDomainSettingsValue copyWith({
    bool? enabled,
    String? host,
    int? port,
    bool? useSsl,
    String? baseDn,
    String? bindDn,
    String? bindPassword,
  }) {
    return AdDomainSettingsValue(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      port: port ?? this.port,
      useSsl: useSsl ?? this.useSsl,
      baseDn: baseDn ?? this.baseDn,
      bindDn: bindDn ?? this.bindDn,
      bindPassword: bindPassword ?? this.bindPassword,
    );
  }
}
