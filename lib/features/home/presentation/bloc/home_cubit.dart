import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GlobalAuthCubit authCubit;

  HomeCubit({required this.authCubit}) : super(HomeInitial());

}
