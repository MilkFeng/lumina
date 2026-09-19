import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';

/// Localized copy for the external sources feature.
///
/// The domain and data layers hand back enums and typed failures, never prose,
/// so the strings live here — with the one exception of [failureReason], which
/// appends the raw platform message because no localized sentence can cover
/// every socket error a device can produce.
extension ExternalSourceLocalizations on AppLocalizations {
  /// Display name of a source [type].
  String externalSourceTypeName(ExternalSourceType type) => switch (type) {
    ExternalSourceType.webdav => externalSourceTypeWebdav,
  };

  /// Message for a failed connection attempt.
  String externalSourceFailureMessage(ExternalSourceFailure failure) {
    final reason = failureReason(failure);
    final detail = failure.detail?.trim();
    // Details are only useful when they add something beyond the sentence, and
    // they are raw platform text, so they stay in parentheses and untranslated.
    return detail == null || detail.isEmpty
        ? externalSourceTestFailed(reason)
        : externalSourceTestFailed('$reason ($detail)');
  }

  /// Short explanation of [failure], without any surrounding sentence.
  String failureReason(ExternalSourceFailure failure) {
    return switch (failure.kind) {
      ExternalSourceFailureKind.auth => externalSourceErrorAuth,
      ExternalSourceFailureKind.notFound => externalSourceErrorNotFound,
      ExternalSourceFailureKind.invalidUrl => externalSourceErrorInvalidUrl,
      ExternalSourceFailureKind.invalidResponse =>
        externalSourceErrorInvalidResponse,
      ExternalSourceFailureKind.timeout => externalSourceErrorTimeout,
      ExternalSourceFailureKind.network => externalSourceErrorNetwork,
      ExternalSourceFailureKind.tls => externalSourceErrorTls,
      ExternalSourceFailureKind.tooLarge => externalSourceErrorTooLarge,
      ExternalSourceFailureKind.duplicateName =>
        externalSourceErrorDuplicateName,
      ExternalSourceFailureKind.status => externalSourceErrorStatus(
        failure.statusCode ?? 0,
      ),
      ExternalSourceFailureKind.unknown => externalSourceErrorUnknown,
    };
  }

  /// Resolves a `labelKey` carried by an [ExternalSourceField].
  ///
  /// The lookup is by key rather than by an enum so that a new source type can
  /// declare its fields — and its strings — without touching the editor dialog.
  String externalSourceFieldLabel(String key) {
    return switch (key) {
      'externalSourceWebdavUrl' => externalSourceWebdavUrl,
      'externalSourceWebdavPath' => externalSourceWebdavPath,
      'externalSourceUsername' => externalSourceUsername,
      'externalSourcePassword' => externalSourcePassword,
      _ => key,
    };
  }

  /// Resolves an optional `hint` key carried by an [ExternalSourceField].
  String? externalSourceFieldHint(String? key) {
    if (key == null) return null;
    return switch (key) {
      'externalSourceWebdavUrlHint' => externalSourceWebdavUrlHint,
      'externalSourceWebdavPathHint' => externalSourceWebdavPathHint,
      _ => null,
    };
  }
}
