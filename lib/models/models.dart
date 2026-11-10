class User {
  final int id;
  final String username;
  final String role;
  final String? createdAt;
  final String? expiresAt;
  final int? daysLeft;
  final int maxBots;
  final bool hasServer;
  final bool autoRestart;
  final int unreadNotifications;

  User({
    required this.id, required this.username, required this.role,
    this.createdAt, this.expiresAt, this.daysLeft,
    this.maxBots = 1, this.hasServer = false,
    this.autoRestart = false, this.unreadNotifications = 0,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] ?? 0,
    username: j['username'] ?? '',
    role: j['role'] ?? 'user',
    createdAt: j['created_at'],
    expiresAt: j['expires_at'],
    daysLeft: j['days_left'],
    maxBots: j['max_bots'] ?? 1,
    hasServer: j['has_server'] ?? false,
    autoRestart: j['auto_restart'] ?? false,
    unreadNotifications: j['unread_notifications'] ?? 0,
  );

  bool get isAdmin => role == 'admin';
}

class ServerResources {
  final String state;
  final String name;
  final int uptimeSeconds;
  final double? cpu;
  final double? memPercent;
  final int memUsed;
  final int memLimit;
  final double? diskPercent;
  final int diskUsed;
  final int diskLimit;
  final int netRx;
  final int netTx;
  final String healthLevel;
  final List<String> healthIssues;

  ServerResources({
    required this.state, required this.name, required this.uptimeSeconds,
    this.cpu, this.memPercent, this.memUsed = 0, this.memLimit = 0,
    this.diskPercent, this.diskUsed = 0, this.diskLimit = 0,
    this.netRx = 0, this.netTx = 0,
    this.healthLevel = 'ok', this.healthIssues = const [],
  });

  factory ServerResources.fromJson(Map<String, dynamic> j) {
    final cpu = j['cpu'] as Map?;
    final mem = j['memory'] as Map?;
    final disk = j['disk'] as Map?;
    final net = j['network'] as Map?;
    final health = j['health'] as Map?;
    return ServerResources(
      state: j['state'] ?? 'unknown',
      name: j['name'] ?? 'server',
      uptimeSeconds: j['uptime_seconds'] ?? 0,
      cpu: (cpu?['percent'] as num?)?.toDouble(),
      memPercent: (mem?['percent'] as num?)?.toDouble(),
      memUsed: (mem?['used'] as num?)?.toInt() ?? 0,
      memLimit: (mem?['limit'] as num?)?.toInt() ?? 0,
      diskPercent: (disk?['percent'] as num?)?.toDouble(),
      diskUsed: (disk?['used'] as num?)?.toInt() ?? 0,
      diskLimit: (disk?['limit'] as num?)?.toInt() ?? 0,
      netRx: (net?['rx'] as num?)?.toInt() ?? 0,
      netTx: (net?['tx'] as num?)?.toInt() ?? 0,
      healthLevel: health?['level'] ?? 'ok',
      healthIssues: (health?['issues'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class BotInfo {
  final String file;
  final String state;
  final int? pid;
  final int? uptime;
  final double? cpu;
  final int? rss;
  final int restarts;
  final int crashCount;
  final int? lastExitCode;
  final int? threads;
  final Map<String, dynamic> policy;
  final List<String> envKeys;

  BotInfo({
    required this.file, required this.state,
    this.pid, this.uptime, this.cpu, this.rss,
    this.restarts = 0, this.crashCount = 0,
    this.lastExitCode, this.threads,
    this.policy = const {}, this.envKeys = const [],
  });

  factory BotInfo.fromJson(Map<String, dynamic> j) => BotInfo(
    file: j['file'] ?? j['name'] ?? '',
    state: j['state'] ?? 'unknown',
    pid: j['pid'],
    uptime: j['uptime'],
    cpu: (j['cpu'] as num?)?.toDouble(),
    rss: j['rss'],
    restarts: j['restarts'] ?? 0,
    crashCount: j['crash_count'] ?? 0,
    lastExitCode: j['last_exit_code'],
    threads: j['threads'],
    policy: (j['policy'] as Map?)?.cast<String, dynamic>() ?? const {},
    envKeys: (j['env_keys'] as List?)?.cast<String>() ?? const [],
  );
}

class BotList {
  final List<BotInfo> bots;
  final bool launcherAlive;
  BotList({required this.bots, required this.launcherAlive});
  factory BotList.fromJson(Map<String, dynamic> j) => BotList(
    bots: (j['bots'] as List? ?? []).map((e) => BotInfo.fromJson(e)).toList(),
    launcherAlive: j['launcher_alive'] ?? false,
  );
}

class FileItem {
  final String name;
  final bool isFile;
  final int size;
  final String? modifiedAt;
  final String? path;

  FileItem({
    required this.name, required this.isFile,
    this.size = 0, this.modifiedAt, this.path,
  });

  factory FileItem.fromJson(Map<String, dynamic> j) => FileItem(
    name: j['name'] ?? '',
    isFile: j['is_file'] ?? false,
    size: j['size'] ?? 0,
    modifiedAt: j['modified_at'],
    path: j['path'],
  );
}

class BackupInfo {
  final String uuid;
  final String name;
  final String state;
  final int bytes;
  final String? createdAt;
  final bool locked;

  BackupInfo({
    required this.uuid, required this.name, required this.state,
    this.bytes = 0, this.createdAt, this.locked = false,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> j) => BackupInfo(
    uuid: j['uuid'] ?? '',
    name: j['name'] ?? '',
    state: j['state'] ?? '?',
    bytes: j['bytes'] ?? 0,
    createdAt: j['created_at'],
    locked: j['locked'] ?? false,
  );
}

class NotificationItem {
  final int id;
  final String kind;
  final String text;
  final bool isRead;
  final String? ts;

  NotificationItem({
    required this.id, required this.kind, required this.text,
    this.isRead = false, this.ts,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
    id: j['id'] ?? 0,
    kind: j['kind'] ?? '?',
    text: j['text'] ?? '',
    isRead: j['is_read'] ?? false,
    ts: j['ts'],
  );
}

class Announcement {
  final int id;
  final String text;
  final String? ts;
  final bool active;
  Announcement({required this.id, required this.text, this.ts, this.active = true});
  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id'] ?? 0, text: j['text'] ?? '',
    ts: j['ts'], active: j['active'] ?? true,
  );
}

class AdminStats {
  final int users, pending, banned, poolFree, poolUsed, logins24h;
  final bool maintenance, registrationOpen, requireApproval;
  AdminStats({
    required this.users, required this.pending, required this.banned,
    required this.poolFree, required this.poolUsed, required this.logins24h,
    required this.maintenance, required this.registrationOpen,
    required this.requireApproval,
  });
  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    users: j['users'] ?? 0, pending: j['pending'] ?? 0,
    banned: j['banned'] ?? 0, poolFree: j['pool_free'] ?? 0,
    poolUsed: j['pool_used'] ?? 0, logins24h: j['logins_24h'] ?? 0,
    maintenance: j['maintenance'] ?? false,
    registrationOpen: j['registration_open'] ?? false,
    requireApproval: j['require_approval'] ?? false,
  );
}

class AdminUser {
  final int id;
  final String username, role, status;
  final bool banned;
  final String? expiresAt;
  AdminUser({
    required this.id, required this.username, required this.role,
    required this.status, this.banned = false, this.expiresAt,
  });
  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] ?? 0, username: j['username'] ?? '',
    role: j['role'] ?? 'user', status: j['status'] ?? '?',
    banned: j['banned'] ?? false, expiresAt: j['expires_at'],
  );

  bool get isAdmin => role == 'admin';
}
