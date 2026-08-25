import 'ad_domain_user.dart';

/// AD 校验（用户认证 / 连接测试）结果状态。
enum AdDomainAuthStatus {
  /// 校验通过。
  success,

  /// 账号或密码错误（bind 失败）。
  invalidCredentials,

  /// 无法连接 AD 服务器或服务器异常。
  unreachable,
}

/// AD 校验结果：用户认证与连接测试共用。
///
/// 通过 [success] / [message] 判断结果；[user] 仅在部分校验路径下返回
/// 用户信息（直接 bind 校验时为 null）。
class AdDomainAuthResult {
  const AdDomainAuthResult.success([this.user])
      : success = true,
        status = AdDomainAuthStatus.success,
        message = null;

  const AdDomainAuthResult.invalidCredentials([this.message = '账号或密码错误'])
      : success = false,
        user = null,
        status = AdDomainAuthStatus.invalidCredentials;

  const AdDomainAuthResult.unreachable(this.message)
      : success = false,
        user = null,
        status = AdDomainAuthStatus.unreachable;

  /// 是否校验通过。
  final bool success;

  /// 校验通过时的用户信息（可能为 null）。
  final AdDomainUser? user;

  final AdDomainAuthStatus status;

  /// 失败/异常时的说明文案。
  final String? message;
}
