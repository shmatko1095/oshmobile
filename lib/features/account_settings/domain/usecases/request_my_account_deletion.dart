import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/usecase/usecase.dart';

class RequestMyAccountDeletion implements UseCase<void, NoParams> {
  const RequestMyAccountDeletion({
    required MobileV1Service mobileService,
  }) : _mobileService = mobileService;

  final MobileV1Service _mobileService;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      final response = await _mobileService.requestMyAccountDeletion();
      MobileV1ResponseMapper.ensureSuccess(response);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure.unexpected(e.message));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
