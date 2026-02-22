import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AccountDrawerHeader extends StatelessWidget {
  const AccountDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final JwtUserData? userData =
        context.read<GlobalAuthCubit>().getJwtUserData();
    if (userData == null) {
      return const SizedBox.shrink();
    }

    final name = userData.name.trim();
    final avatarText =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: AppSolidCard(
        backgroundColor: AppPalette.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 30,
              backgroundColor: AppPalette.surfaceAlt,
              child: Text(
                avatarText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
