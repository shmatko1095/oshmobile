class DeviceConfig {
  final Set<String> capabilities;
  final Set<String> hidden;
  final List<String> order;

  const DeviceConfig({this.capabilities = const {}, this.hidden = const {}, this.order = const []});

  factory DeviceConfig.fromJson(Map<String, dynamic>? j) {
    j = j ?? {};
    final caps = ((j['capabilities'] ?? const []) as List).cast<String>().toSet();
    final hints = (j['ui_hints'] as Map?) ?? const {};
    final hidden = ((hints['dashboard.hidden'] ?? const []) as List).cast<String>().toSet();
    final order = ((hints['dashboard.order'] ?? const []) as List).cast<String>();
    return DeviceConfig(capabilities: caps, hidden: hidden, order: order);
  }

  bool has(String cap) => capabilities.contains(cap);

  bool visible(String id) => !hidden.contains(id);
}
