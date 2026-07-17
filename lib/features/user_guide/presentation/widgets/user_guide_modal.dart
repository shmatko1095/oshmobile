import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_state.dart';
import 'package:oshmobile/features/user_guide/presentation/widgets/user_guide_live_metrics_illustration.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'user_guide_modal_state.dart';

class UserGuideModal extends StatefulWidget {
  const UserGuideModal({
    super.key,
    required this.cubit,
  });

  final UserGuideCubit cubit;

  @override
  State<UserGuideModal> createState() => _UserGuideModalState();
}
