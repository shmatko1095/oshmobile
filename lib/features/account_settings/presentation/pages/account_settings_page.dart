import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:oshmobile/features/account_settings/domain/models/app_theme_preference.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_deletion_request_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  static MaterialPageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const AccountSettingsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountSettingsCubit>(
      create: (_) => AccountSettingsCubit(
        appThemeCubit: context.read<AppThemeCubit>(),
        requestMyAccountDeletion: locator<RequestMyAccountDeletion>(),
      ),
      child: const _AccountSettingsView(),
    );
  }
}

class _AccountSettingsView extends StatelessWidget {
  const _AccountSettingsView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final userData = context.read<GlobalAuthCubit>().getJwtUserData();
    final userName = userData?.name.trim() ?? '';
    final email = userData?.email.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.ProfileAndSettings),
      ),
      body: SafeArea(
        child: BlocBuilder<AccountSettingsCubit, AccountSettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildProfileCard(context, userName, email),
                const SizedBox(height: 12),
                _buildApplicationSettingsCard(context, state),
                const SizedBox(height: 12),
                _buildAccountSettingsCard(context, state, email),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String userName,
    String email,
  ) {
    final s = S.of(context);
    final safeName = userName.isEmpty ? s.Account : userName;
    final avatarText =
        safeName.isNotEmpty ? safeName.substring(0, 1).toUpperCase() : 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppPalette.surface : Colors.white;
    final avatarSurface =
        isDark ? AppPalette.surfaceAlt : const Color(0xFFF1F3F5);
    final titleColor =
        isDark ? AppPalette.textPrimary : const Color(0xFF111827);
    final subtitleColor =
        isDark ? AppPalette.textSecondary : const Color(0xFF4B5563);

    return AppSolidCard(
      backgroundColor: surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarSurface,
            child: Text(
              avatarText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationSettingsCard(
    BuildContext context,
    AccountSettingsState state,
  ) {
    final s = S.of(context);
    final cubit = context.read<AccountSettingsCubit>();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              s.ApplicationSettings,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          _buildThemeTile(
            context,
            title: s.ThemeSystem,
            value: AppThemePreference.system,
            groupValue: state.selectedTheme,
            onSelected: cubit.changeTheme,
            showDivider: true,
          ),
          _buildThemeTile(
            context,
            title: s.ThemeDark,
            value: AppThemePreference.dark,
            groupValue: state.selectedTheme,
            onSelected: cubit.changeTheme,
            showDivider: true,
          ),
          _buildThemeTile(
            context,
            title: s.ThemeLight,
            value: AppThemePreference.light,
            groupValue: state.selectedTheme,
            onSelected: cubit.changeTheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard(
    BuildContext context,
    AccountSettingsState state,
    String email,
  ) {
    final s = S.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              s.AccountSettings,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: AppPalette.destructiveFg,
            ),
            title: Text(
              s.DeleteAccount,
              style: const TextStyle(
                color: AppPalette.destructiveFg,
              ),
            ),
            trailing: state.isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF6B7280),
                  ),
            onTap: state.isDeleting
                ? null
                : () => _onDeleteAccountTap(context, email),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteAccountTap(BuildContext context, String email) async {
    await Navigator.of(context).push(
      AccountDeletionRequestPage.route(
        cubit: context.read<AccountSettingsCubit>(),
        email: email,
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required AppThemePreference value,
    required AppThemePreference groupValue,
    required ValueChanged<AppThemePreference> onSelected,
    required bool showDivider,
  }) {
    final selected = groupValue == value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color:
                selected ? AppPalette.accentPrimary : const Color(0xFF6B7280),
          ),
          onTap: () => onSelected(value),
          selected: selected,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
