/// Bootstrap payload returned by GET /client/bootstrap.
class Bootstrap {
  final bool killSwitch;
  final String killReason;
  final bool maintenance;
  final String? maintenanceMessage;
  final UpdateInfo? update;
  final List<ModalInfo> modals;
  final List<BannerInfo> banners;
  final TokenPolicy? tokenPolicy;

  Bootstrap({
    required this.killSwitch,
    required this.killReason,
    required this.maintenance,
    this.maintenanceMessage,
    this.update,
    required this.modals,
    required this.banners,
    this.tokenPolicy,
  });

  factory Bootstrap.fromJson(Map<String, dynamic> j) => Bootstrap(
        killSwitch: j['kill_switch'] ?? false,
        killReason: j['kill_reason'] ?? 'Service unavailable.',
        maintenance: j['maintenance'] ?? false,
        maintenanceMessage: j['maintenance_message'],
        update: j['update'] != null
            ? UpdateInfo.fromJson(Map<String, dynamic>.from(j['update']))
            : null,
        modals: (j['modals'] as List? ?? [])
            .map((e) => ModalInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        banners: (j['banners'] as List? ?? [])
            .map((e) => BannerInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        tokenPolicy: j['token_policy'] != null
            ? TokenPolicy.fromJson(Map<String, dynamic>.from(j['token_policy']))
            : null,
      );
}

class UpdateInfo {
  final String version;
  final String title;
  final String message;
  final bool force;
  final String? downloadUrl;
  final String? minSupported;
  final String? platform;

  UpdateInfo({
    required this.version,
    required this.title,
    required this.message,
    required this.force,
    this.downloadUrl,
    this.minSupported,
    this.platform,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        version: j['version'] ?? '',
        title: j['title'] ?? 'Update',
        message: j['message'] ?? '',
        force: j['force'] ?? false,
        downloadUrl: j['download_url'],
        minSupported: j['min_supported'],
        platform: j['platform'],
      );
}

class ModalInfo {
  final int id;
  final String type; // info|warning|error|success|update|promo|gift
  final String title;
  final String message;
  final String icon; // auto|download|warning|server|gift|info
  final List<ModalButton> buttons;
  final bool forceShow;
  final bool showOnce;
  final String? showTo;
  final String? expiresAt;

  ModalInfo({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.icon = 'auto',
    this.buttons = const [],
    this.forceShow = false,
    this.showOnce = true,
    this.showTo,
    this.expiresAt,
  });

  factory ModalInfo.fromJson(Map<String, dynamic> j) => ModalInfo(
        id: j['id'] ?? 0,
        type: j['type'] ?? 'info',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        icon: j['icon'] ?? 'auto',
        buttons: (j['buttons'] as List? ?? [])
            .map((e) => ModalButton.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        forceShow: j['force_show'] ?? false,
        showOnce: j['show_once'] ?? true,
        showTo: j['show_to'],
        expiresAt: j['expires_at'],
      );
}

class ModalButton {
  final String text;
  final String style; // primary|ghost|danger
  final String action; // url|close|copy
  final String? url;
  final String? value;

  ModalButton({
    required this.text,
    this.style = 'primary',
    this.action = 'close',
    this.url,
    this.value,
  });

  factory ModalButton.fromJson(Map<String, dynamic> j) => ModalButton(
        text: j['text'] ?? '',
        style: j['style'] ?? 'primary',
        action: j['action'] ?? 'close',
        url: j['url'],
        value: j['value'],
      );
}

class BannerInfo {
  final int id;
  final String text;
  final String color; // primary|warning|error|success|info
  final String? actionUrl;
  final String? icon;

  BannerInfo({
    required this.id,
    required this.text,
    this.color = 'primary',
    this.actionUrl,
    this.icon,
  });

  factory BannerInfo.fromJson(Map<String, dynamic> j) => BannerInfo(
        id: j['id'] ?? 0,
        text: j['text'] ?? '',
        color: j['color'] ?? 'primary',
        actionUrl: j['action_url'],
        icon: j['icon'],
      );
}

class TokenPolicy {
  final int accessTtlSeconds;
  final int refreshTtlSeconds;

  TokenPolicy({
    required this.accessTtlSeconds,
    required this.refreshTtlSeconds,
  });

  factory TokenPolicy.fromJson(Map<String, dynamic> j) => TokenPolicy(
        accessTtlSeconds: j['access_ttl_seconds'] ?? 3600,
        refreshTtlSeconds: j['refresh_ttl_seconds'] ?? 2592000,
      );
}
