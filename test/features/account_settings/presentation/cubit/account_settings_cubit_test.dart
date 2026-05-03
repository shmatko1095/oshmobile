import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';

void main() {
  late _FakeThemeModeStorage themeModeStorage;
  late AppThemeCubit appThemeCubit;
  late _FakeRequestMyAccountDeletion requestMyAccountDeletion;
  late _FakeStartupClientPolicyRepository clientPolicyRepository;
  late _FakeAppClientMetadataProvider metadataProvider;

  setUp(() {
    themeModeStorage = _FakeThemeModeStorage();
    appThemeCubit = AppThemeCubit(storage: themeModeStorage);
    requestMyAccountDeletion = _FakeRequestMyAccountDeletion();
    clientPolicyRepository = _FakeStartupClientPolicyRepository();
    metadataProvider = _FakeAppClientMetadataProvider(
      const AppClientMetadata(
        platform: 'android',
        appVersion: '1.2.3',
        build: 42,
      ),
    );

    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
    OshCrashReporter.debugSetBackend(const _NoopCrashReporterBackend());
  });

  tearDown(() async {
    OshAnalytics.debugResetBackend();
    OshCrashReporter.debugResetBackend();
    await appThemeCubit.close();
  });

  test('preloads installed app version label', () async {
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.installedVersionLabel, '1.2.3 (42)');
  });

  test('manual check emits latest-installed outcome when policy allows',
      () async {
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.checkAppVersion();

    expect(cubit.state.isCheckingVersion, isFalse);
    expect(
      cubit.state.pendingVersionCheckOutcome?.type,
      AccountSettingsVersionCheckOutcomeType.latestInstalled,
    );
  });

  test('manual check emits recommend-update outcome', () async {
    clientPolicyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.recommendUpdate,
      policy: _samplePolicy,
    );
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.checkAppVersion();

    expect(
      cubit.state.pendingVersionCheckOutcome?.type,
      AccountSettingsVersionCheckOutcomeType.recommendUpdate,
    );
    expect(cubit.state.pendingVersionCheckOutcome?.policy?.policyVersion, 12);
  });

  test('manual check emits require-update outcome', () async {
    clientPolicyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.requireUpdate,
      policy: _samplePolicy,
    );
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.checkAppVersion();

    expect(
      cubit.state.pendingVersionCheckOutcome?.type,
      AccountSettingsVersionCheckOutcomeType.requireUpdate,
    );
  });

  test('manual check emits failed outcome for fail-open decision', () async {
    clientPolicyRepository.nextDecision = const MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.allow,
      failOpen: true,
    );
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.checkAppVersion();

    expect(
      cubit.state.pendingVersionCheckOutcome?.type,
      AccountSettingsVersionCheckOutcomeType.failed,
    );
  });

  test('manual check emits failed outcome for thrown exception', () async {
    clientPolicyRepository.throwOnCheck = StateError('boom');
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.checkAppVersion();

    expect(
      cubit.state.pendingVersionCheckOutcome?.type,
      AccountSettingsVersionCheckOutcomeType.failed,
    );
  });

  test('changeTheme keeps app theme cubit in sync', () async {
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    cubit.changeTheme(AppThemePreference.dark);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.selectedTheme, AppThemePreference.dark);
    expect(appThemeCubit.state, ThemeMode.dark);
    expect(themeModeStorage.lastWritten, ThemeMode.dark);
  });

  test('deleteAccount toggles isDeleting around request', () async {
    final completer = Completer<void>();
    requestMyAccountDeletion.completer = completer;
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    final emitted = <AccountSettingsState>[];
    final sub = cubit.stream.listen(emitted.add);
    addTearDown(sub.cancel);

    final future = cubit.deleteAccount();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isDeleting, isTrue);

    completer.complete();
    await future;
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isDeleting, isFalse);
    expect(emitted.any((state) => state.isDeleting), isTrue);
    expect(emitted.last.isDeleting, isFalse);
  });

  test('later tap suppresses recommend prompt for policy version', () async {
    final cubit = _createCubit(
      appThemeCubit: appThemeCubit,
      requestMyAccountDeletion: requestMyAccountDeletion,
      clientPolicyRepository: clientPolicyRepository,
      metadataProvider: metadataProvider,
    );
    addTearDown(cubit.close);

    await cubit.onRecommendUpdateLaterTapped(policy: _samplePolicy);

    expect(clientPolicyRepository.suppressedPolicyVersion, 12);
  });
}

AccountSettingsCubit _createCubit({
  required AppThemeCubit appThemeCubit,
  required _FakeRequestMyAccountDeletion requestMyAccountDeletion,
  required _FakeStartupClientPolicyRepository clientPolicyRepository,
  required _FakeAppClientMetadataProvider metadataProvider,
}) {
  return AccountSettingsCubit(
    appThemeCubit: appThemeCubit,
    requestMyAccountDeletion: requestMyAccountDeletion,
    clientPolicyRepository: clientPolicyRepository,
    appClientMetadataProvider: metadataProvider,
  );
}

final MobileClientPolicy _samplePolicy = MobileClientPolicy(
  minSupportedVersion: '1.0.0',
  latestVersion: '2.0.0',
  storeUrl: 'https://example.com/store',
  policyVersion: 12,
  checkedAt: DateTime.utc(2026, 4, 16, 12),
  fetchedAt: DateTime.utc(2026, 4, 16, 12),
);

class _FakeThemeModeStorage implements ThemeModeStorage {
  ThemeMode lastWritten = ThemeMode.system;

  @override
  ThemeMode readThemeMode() => ThemeMode.system;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    lastWritten = mode;
  }
}

class _FakeRequestMyAccountDeletion extends RequestMyAccountDeletion {
  _FakeRequestMyAccountDeletion()
      : super(mobileService: _FakeMobileV1Service());

  Completer<void>? completer;
  Failure? failure;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    await completer?.future;
    if (failure != null) {
      return left(failure!);
    }
    return right(null);
  }
}

class _FakeStartupClientPolicyRepository
    implements StartupClientPolicyRepository {
  MobileClientPolicyDecision nextDecision = const MobileClientPolicyDecision(
    status: MobileClientPolicyStatus.allow,
  );
  Object? throwOnCheck;
  int? suppressedPolicyVersion;
  Completer<MobileClientPolicyDecision>? inFlight;

  @override
  Future<MobileClientPolicyDecision> checkPolicy() async {
    if (throwOnCheck != null) {
      throw throwOnCheck!;
    }
    if (inFlight != null) {
      return inFlight!.future;
    }
    return nextDecision;
  }

  @override
  Future<void> suppressRecommendPrompt({required int policyVersion}) async {
    suppressedPolicyVersion = policyVersion;
  }
}

class _FakeAppClientMetadataProvider implements AppClientMetadataProvider {
  _FakeAppClientMetadataProvider(this.metadata);

  final AppClientMetadata metadata;

  @override
  Future<AppClientMetadata> getMetadata() async => metadata;
}

class _FakeMobileV1Service extends MobileV1Service {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}

class _NoopCrashReporterBackend implements CrashReporterBackend {
  const _NoopCrashReporterBackend();

  @override
  void log(String message) {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserId(String userId) async {}
}
