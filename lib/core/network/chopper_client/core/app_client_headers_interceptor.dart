import 'dart:async';

import 'package:chopper/chopper.dart';

import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/network_utils/extensions.dart';

class AppClientHeadersInterceptor implements Interceptor {
  AppClientHeadersInterceptor({
    required AppClientMetadataProvider metadataProvider,
  }) : _metadataProvider = metadataProvider;

  final AppClientMetadataProvider _metadataProvider;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;
    if (!request.isOshApiRequest) {
      return chain.proceed(request);
    }

    final metadata = await _metadataProvider.getMetadata();

    var processed = applyHeader(
      request,
      'X-App-Platform',
      metadata.platform,
      override: true,
    );
    processed = applyHeader(
      processed,
      'X-App-Version',
      metadata.appVersion,
      override: true,
    );

    final build = metadata.build;
    if (build != null) {
      processed = applyHeader(
        processed,
        'X-App-Build',
        '$build',
        override: true,
      );
    }

    return chain.proceed(processed);
  }
}
