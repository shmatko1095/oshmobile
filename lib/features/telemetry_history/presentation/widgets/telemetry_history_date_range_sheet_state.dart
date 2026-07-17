part of 'telemetry_history_date_range_sheet.dart';

class TelemetryHistoryDateRangeSheetState
    extends State<TelemetryHistoryDateRangeSheet> {
  late List<DateTime?> _selectedDates;
  late DateTime _displayedMonthLocal;

  DateTime get _today => DateUtils.dateOnly(widget.nowLocal.toLocal());

  DateTime? get _selectedStart =>
      _selectedDates.isEmpty ? null : _selectedDates.first;

  DateTime? get _selectedEnd =>
      _selectedDates.length < 2 ? null : _selectedDates[1];

  bool get _hasCompleteRange => _selectedStart != null && _selectedEnd != null;

  bool get _isRangeTooLong {
    final start = _selectedStart;
    final end = _selectedEnd;
    if (start == null || end == null) return false;
    final window = TelemetryHistoryWindow.custom(
      startLocal: start,
      endInclusiveLocal: end,
    );
    return !widget.retentionPolicy.allowsCustomWindow(
      window,
      nowLocal: widget.nowLocal,
    );
  }

  bool get _canApply => _hasCompleteRange && !_isRangeTooLong;

  @override
  void initState() {
    super.initState();
    _displayedMonthLocal = widget.displayedMonthLocal;
    final initialRange = widget.initialRange;
    _selectedDates = initialRange == null
        ? <DateTime?>[]
        : <DateTime?>[
            DateUtils.dateOnly(initialRange.start),
            DateUtils.dateOnly(initialRange.end),
          ];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppPalette.historySurface : AppPalette.white;
    final secondarySurface =
        isDark ? AppPalette.historySurfaceAlt : AppPalette.lightSurfaceSubtle;
    final border = isDark
        ? AppPalette.historyBorder.withValues(alpha: 0.72)
        : AppPalette.lightBorderStrong;
    final primaryText =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextPrimary;
    final secondaryText = isDark
        ? AppPalette.historyTextSecondary
        : AppPalette.lightTextSecondary;
    final disabledText = isDark
        ? AppPalette.historyTextSecondary.withValues(alpha: 0.48)
        : AppPalette.lightTextDisabled;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animationDuration =
        disableAnimations ? Duration.zero : AppPalette.motionBase;

    final calendarTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppPalette.accentPrimary,
            onPrimary: AppPalette.white,
            surface: surface,
            onSurface: primaryText,
          ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryText),
      ),
    );

    return Material(
      key: const ValueKey('telemetry-history-date-range-sheet'),
      color: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppPalette.radiusLg),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: AppPalette.spaceSm),
          Semantics(
            container: true,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryText.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPalette.spaceXl,
              AppPalette.spaceLg,
              AppPalette.spaceXl,
              AppPalette.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.TelemetryHistoryCalendarTitle,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppPalette.spaceXs),
                Text(
                  s.TelemetryHistoryCalendarHint,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppPalette.spaceLg),
                Semantics(
                  liveRegion: true,
                  label: _selectionLabel(s, localeTag),
                  child: Container(
                    key: const ValueKey(
                      'telemetry-history-date-range-selection',
                    ),
                    constraints: const BoxConstraints(minHeight: 52),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPalette.spaceLg,
                      vertical: AppPalette.spaceMd,
                    ),
                    decoration: BoxDecoration(
                      color: secondarySurface,
                      borderRadius: BorderRadius.circular(AppPalette.radiusMd),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      _selectionLabel(s, localeTag),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedStart == null
                            ? secondaryText
                            : primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: animationDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _isRangeTooLong
                      ? Semantics(
                          key: const ValueKey(
                            'telemetry-history-date-range-error',
                          ),
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: AppPalette.spaceSm,
                            ),
                            child: Text(
                              s.TelemetryHistoryCalendarRangeTooLong,
                              style: const TextStyle(
                                color: AppPalette.destructiveFg,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPalette.spaceSm,
              ),
              child: Theme(
                data: calendarTheme,
                child: CalendarDatePicker2(
                  key: const ValueKey('telemetry-history-date-range-calendar'),
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.range,
                    calendarViewMode: CalendarDatePicker2Mode.day,
                    firstDate: widget.firstDateLocal,
                    lastDate: _today,
                    currentDate: _today,
                    firstDayOfWeek: DateTime.monday,
                    rangeBidirectional: true,
                    allowSameValueSelection: true,
                    dynamicCalendarRows: true,
                    animateToDisplayedMonthDate: !disableAnimations,
                    controlsHeight: 52,
                    dayMaxWidth: 44,
                    centerAlignModePicker: true,
                    controlsTextStyle: TextStyle(
                      color: primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    weekdayLabelTextStyle: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    dayTextStyle: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    todayTextStyle: const TextStyle(
                      color: AppPalette.accentPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    disabledDayTextStyle: TextStyle(
                      color: disabledText,
                      fontSize: 13,
                    ),
                    selectedDayTextStyle: const TextStyle(
                      color: AppPalette.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedRangeDayTextStyle: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedDayHighlightColor: AppPalette.accentPrimary,
                    selectedRangeHighlightColor:
                        AppPalette.accentPrimary.withValues(alpha: 0.18),
                    dayBorderRadius:
                        BorderRadius.circular(AppPalette.radiusPill),
                    lastMonthIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: secondaryText,
                    ),
                    nextMonthIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: secondaryText,
                    ),
                    monthTextStyle: TextStyle(color: primaryText),
                    selectedMonthTextStyle: const TextStyle(
                      color: AppPalette.white,
                      fontWeight: FontWeight.w700,
                    ),
                    disabledMonthTextStyle: TextStyle(color: disabledText),
                    yearTextStyle: TextStyle(color: primaryText),
                    selectedYearTextStyle: const TextStyle(
                      color: AppPalette.white,
                      fontWeight: FontWeight.w700,
                    ),
                    disabledYearTextStyle: TextStyle(color: disabledText),
                  ),
                  value: _selectedDates,
                  displayedMonthDate: _displayedMonthLocal,
                  onDisplayedMonthChanged: (month) {
                    _displayedMonthLocal = month;
                  },
                  onValueChanged: (dates) {
                    setState(() {
                      _selectedDates = dates
                          .map<DateTime?>(DateUtils.dateOnly)
                          .toList(growable: false);
                    });
                  },
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppPalette.spaceXl,
                  AppPalette.spaceMd,
                  AppPalette.spaceXl,
                  AppPalette.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey(
                          'telemetry-history-date-range-cancel',
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: secondaryText,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppPalette.radiusMd),
                          ),
                        ),
                        child: Text(s.TelemetryHistoryCalendarCancel),
                      ),
                    ),
                    const SizedBox(width: AppPalette.spaceMd),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey(
                          'telemetry-history-date-range-apply',
                        ),
                        onPressed: _canApply ? _apply : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.accentPrimary,
                          foregroundColor: AppPalette.white,
                          disabledBackgroundColor:
                              AppPalette.accentPrimary.withValues(alpha: 0.2),
                          disabledForegroundColor:
                              AppPalette.white.withValues(alpha: 0.45),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppPalette.radiusMd),
                          ),
                        ),
                        child: Text(s.TelemetryHistoryCalendarApply),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _selectionLabel(S s, String localeTag) {
    final start = _selectedStart;
    final end = _selectedEnd;
    if (start == null) return s.TelemetryHistoryCalendarHint;
    if (end == null) {
      return '${telemetryHistorySingleDateLabel(
        dateLocal: start,
        localeTag: localeTag,
      )} – …';
    }
    return telemetryHistoryDateRangeLabel(
      startLocal: start,
      endInclusiveLocal: end,
      localeTag: localeTag,
    );
  }

  void _apply() {
    final start = _selectedStart;
    final end = _selectedEnd;
    if (!_canApply || start == null || end == null) return;
    Navigator.of(context).pop(DateTimeRange(start: start, end: end));
  }
}
