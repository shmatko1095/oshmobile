import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/mobile/mobile_api_client.dart';
import 'package:oshmobile/core/usecase/usecase.dart';

class RequestMyAccountDeletion implements UseCase<void, NoParams> {
  const RequestMyAccountDeletion({
    required MobileApiClient mobileApiClient,
  }) : _mobileApiClient = mobileApiClient;

  final MobileApiClient _mobileApiClient;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _mobileApiClient.requestMyAccountDeletion();
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
