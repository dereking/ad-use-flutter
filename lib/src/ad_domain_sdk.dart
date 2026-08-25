import 'ad_domain_settings_value.dart';

/// AD SDK 全局默认配置：由 shell 在初始化时通过 [initialize] 提供。
///
/// [AdDomainSettingsCard] 在用户尚未配置（值为空）时使用这些默认参数预填，
/// 让 shell（如 GSpace）能随自身默认的 AD 域服务器参数初始化 ad sdk。
class AdDomainSdk {
  static AdDomainSettingsValue? _defaults;

  /// 提供默认 AD 域服务器参数。shell 应在初始化 ad sdk 时调用。
  static void initialize({AdDomainSettingsValue? defaults}) {
    _defaults = defaults;
  }

  /// 默认 AD 域服务器参数；未初始化时为 null。
  static AdDomainSettingsValue? get defaults => _defaults;

  static void resetForTesting() {
    _defaults = null;
  }
}
