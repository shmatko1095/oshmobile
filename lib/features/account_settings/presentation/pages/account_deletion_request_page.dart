import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_state.dart';
import 'package:oshmobile/generated/l10n.dart';

class AccountDeletionRequestPage extends StatefulWidget {
  const AccountDeletionRequestPage({
    required this.email,
    super.key,
  });

  final String email;

  static MaterialPageRoute<void> route({
    required AccountSettingsCubit cubit,
    required String email,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AccountDeletionRequestPage(email: email),
      ),
    );
  }

  @override
  State<AccountDeletionRequestPage> createState() =>
      _AccountDeletionRequestPageState();
}

class _AccountDeletionRequestPageState
    extends State<AccountDeletionRequestPage> {
  bool _isRequestSent = false;

  String get _normalizedEmail => widget.email.trim();

  Future<void> _sendDeletionConfirmationEmail() async {
    final s = S.of(context);
    try {
      await context.read<AccountSettingsCubit>().deleteAccount();
      if (!mounted) return;
      setState(() {
        _isRequestSent = true;
      });
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        StateError(:final message) when message.isNotEmpty => message,
        _ => s.UnknownError,
      };
      SnackBarUtils.showFail(
        context: context,
        content: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = context.watch<AccountSettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.DeleteAccount),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isRequestSent
                ? _buildSuccessState(context)
                : _buildRequestState(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestState(BuildContext context, AccountSettingsState state) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextMuted;
    final safeEmail = _normalizedEmail.isEmpty ? '—' : _normalizedEmail;

    return Column(
      key: const ValueKey('request-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          CupertinoIcons.mail_solid,
          color: AppPalette.accentPrimary,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          s.DeleteAccountEmailFlowTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          s.DeleteAccountEmailFlowDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AppSolidCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.Email,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: secondaryTextColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                safeEmail,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                s.DeleteAccountEmailFlowPendingNote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AppButton(
          text: s.DeleteAccountEmailFlowSendButton,
          onPressed: state.isDeleting ? null : _sendDeletionConfirmationEmail,
          isLoading: state.isDeleting,
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextMuted;
    final safeEmail = _normalizedEmail.isEmpty ? '—' : _normalizedEmail;

    return Column(
      key: const ValueKey('success-state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: AppPalette.accentPrimary,
          size: 76,
        ),
        const SizedBox(height: 16),
        Text(
          s.CheckYourEmail,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          s.DeleteAccountEmailFlowSuccessDescription(safeEmail),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          s.DeleteAccountEmailFlowSuccessHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        AppButton(
          text: s.Done,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
