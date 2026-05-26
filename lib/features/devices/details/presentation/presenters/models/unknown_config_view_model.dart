enum UnknownConfigAction {
  refresh,
}

enum UnknownConfigTip {
  ensureAppUpdated,
  checkNetwork,
  contactSupport,
}

class UnknownConfigMeta {
  const UnknownConfigMeta({
    required this.isOnline,
    required this.serial,
    required this.modelId,
    required this.modelName,
    required this.layout,
    required this.configurationId,
    required this.revision,
    required this.status,
    required this.firmwareVersion,
    required this.deviceId,
    required this.controlsCount,
    required this.widgetsCount,
    required this.controlIds,
  });

  final bool isOnline;
  final String serial;
  final String modelId;
  final String modelName;
  final String layout;
  final String configurationId;
  final int revision;
  final String status;
  final String firmwareVersion;
  final String deviceId;
  final int controlsCount;
  final int widgetsCount;
  final List<String> controlIds;
}

class UnknownConfigViewModel {
  const UnknownConfigViewModel({
    required this.alias,
    required this.meta,
    required this.actions,
    required this.tips,
  });

  final String alias;
  final UnknownConfigMeta meta;
  final List<UnknownConfigAction> actions;
  final List<UnknownConfigTip> tips;
}
