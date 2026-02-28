import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/contracts/contract_negotiator.dart';
import 'package:oshmobile/core/contracts/device_contracts_models.dart';
import 'package:oshmobile/core/contracts/device_contracts_repository.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/core/profile/profile_bundle_repository.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class GetDeviceFull {
  final DeviceRepository deviceRepository;
  final DeviceContractsRepository contractsRepository;
  final ContractNegotiator contractNegotiator;
  final ProfileBundleRepository profileBundleRepository;
  final DeviceRuntimeContracts runtimeContracts;

  GetDeviceFull({
    required this.deviceRepository,
    required this.contractsRepository,
    required this.contractNegotiator,
    required this.profileBundleRepository,
    required this.runtimeContracts,
  });

  Future<
      ({
        Device device,
        DeviceProfileBundle bundle,
        NegotiatedContractSet negotiated,
      })> call(String deviceId) async {
    final Either<Failure, Device> res = await deviceRepository.get(
      deviceId: deviceId,
    );

    return await res.fold(
      (f) => Future.error(f.message ?? 'Failed to load device'),
      (d) async {
        runtimeContracts.reset();
        final attempt = await _negotiateContracts();
        final initialNegotiated = attempt.negotiated;
        final bundle = await profileBundleRepository.fetchBundle(
          serial: d.sn,
          modelId: d.modelId,
          negotiatedSchemas: initialNegotiated?.allSchemas ?? const <String>{},
        );
        final negotiated = _resolveNegotiated(
          attempt: attempt,
          bundle: bundle,
        );
        _validateCompatibility(
          attempt: attempt,
          bundle: bundle,
          negotiated: negotiated,
        );
        runtimeContracts.applyNegotiated(negotiated);
        final hydratedBundle = bundle.copyWith(
          negotiatedSchemas: negotiated.allSchemas,
          readableDomains: negotiated.domains.values
              .where((domain) => domain.readable)
              .map((domain) => domain.domain)
              .toSet(),
          patchableDomains: negotiated.domains.values
              .where((domain) => domain.patchable)
              .map((domain) => domain.domain)
              .toSet(),
          settableDomains: negotiated.domains.values
              .where((domain) => domain.settable)
              .map((domain) => domain.domain)
              .toSet(),
          negotiatedFeaturesByDomain: <String, Set<String>>{
            for (final entry in negotiated.domains.entries)
              entry.key: Set<String>.unmodifiable(entry.value.features),
          },
        );

        return (device: d, bundle: hydratedBundle, negotiated: negotiated);
      },
    );
  }

  Future<_NegotiationAttempt> _negotiateContracts() async {
    try {
      final contracts = await contractsRepository.fetch();
      return _NegotiationAttempt(
        negotiated: contractNegotiator.negotiate(contracts),
      );
    } catch (error) {
      return _NegotiationAttempt(error: error);
    }
  }

  NegotiatedContractSet _resolveNegotiated({
    required _NegotiationAttempt attempt,
    required DeviceProfileBundle bundle,
  }) {
    if (attempt.negotiated case final negotiated?) {
      return negotiated;
    }

    final bootstrap = bundle.modelProfile.osh.bootstrap;
    if (bootstrap.contractsRequired || !bootstrap.legacyFallbackAllowed) {
      throw CompatibilityError(
        'This device requires contract negotiation but the bootstrap contract is unavailable.',
      );
    }

    return contractNegotiator.legacyFallbackConservative();
  }

  void _validateCompatibility({
    required _NegotiationAttempt attempt,
    required DeviceProfileBundle bundle,
    required NegotiatedContractSet negotiated,
  }) {
    final missingRequiredDomains = <String>[];
    for (final entry in bundle.modelProfile.osh.domains.entries) {
      if (!entry.value.required) continue;
      if (!negotiated.canRead(entry.key)) {
        missingRequiredDomains.add(entry.key);
      }
    }

    if (missingRequiredDomains.isEmpty) return;

    if (attempt.negotiated != null) {
      throw UpdateAppRequired(
        'Update required. Unsupported required domains: ${missingRequiredDomains.join(', ')}.',
      );
    }

    throw CompatibilityError(
      'Compatibility error. Required domains are unavailable: ${missingRequiredDomains.join(', ')}.',
    );
  }
}

class UpdateAppRequired implements Exception {
  final String message;

  const UpdateAppRequired(this.message);

  @override
  String toString() => message;
}

class CompatibilityError implements Exception {
  final String message;

  const CompatibilityError(this.message);

  @override
  String toString() => message;
}

class _NegotiationAttempt {
  final NegotiatedContractSet? negotiated;
  final Object? error;

  const _NegotiationAttempt({
    this.negotiated,
    this.error,
  });
}
