import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AccountDrawerHeader extends StatelessWidget {
  const AccountDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    JwtUserData? userData = context.read<GlobalAuthCubit>().getJwtUserData();
    if (userData == null) {
      return SizedBox.shrink();
    } else {
      return UserAccountsDrawerHeader(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(0.8, 1),
            colors: <Color>[
              AppPalette.gradient2,
              AppPalette.gradient3,
            ],
            tileMode: TileMode.mirror,
          ),
        ),
        otherAccountsPictures: const [Icon(Icons.manage_accounts, size: 28.0)],
        accountName: Text(userData.name, style: TextStyle(fontSize: 22)),
        accountEmail: Text(userData.email),
      );
    }
  }
}
