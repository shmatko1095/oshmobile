class OshConfig {
  final Set<String> capabilities;
  final Set<String> hidden;
  final List<String> order;

  const OshConfig({this.capabilities = const {}, this.hidden = const {}, this.order = const []});

  factory OshConfig.fromJson(Map<String, dynamic>? j) {
    j = j ?? {};
    final caps = ((j['capabilities'] ?? const []) as List).cast<String>().toSet();
    final hints = (j['ui_hints'] as Map?) ?? const {};
    final hidden = ((hints['dashboard.hidden'] ?? const []) as List).cast<String>().toSet();
    final order = ((hints['dashboard.order'] ?? const []) as List).cast<String>();
    return OshConfig(capabilities: caps, hidden: hidden, order: order);
  }

  bool has(String cap) => capabilities.contains(cap);

  bool visible(String id) => !hidden.contains(id);
}
