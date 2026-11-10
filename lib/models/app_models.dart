/// Data model for the single-app mode (/app endpoints).

class AppStatus {
  final String state;          // running / stopped / starting / crashed / ...
  final String name;
  final int uptimeSeconds;
  final AppResources resources;
  final AppFileInfo app;

  AppStatus({
    required this.state,
    required this.name,
    required this.uptimeSeconds,
    required this.resources,
    required this.app,
  });

  factory AppStatus.fromJson(Map<String, dynamic> j) => AppStatus(
        state: j['state'] ?? 'unknown',
        name: j['name'] ?? 'server',
        uptimeSeconds: _readInt(j['uptime_seconds']),
        resources: AppResources.fromJson(
            (j['resources'] as Map?)?.cast<String, dynamic>() ?? {}),
        app: AppFileInfo.fromJson(
            (j['app'] as Map?)?.cast<String, dynamic>() ?? {}),
      );
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class AppResources {
  final double? cpuPercent;
  final double? cpuLimit;
  final double? memoryPercent;
  final int memoryBytes;
  final int memoryLimit;
  final double? diskPercent;
  final int diskBytes;
  final int diskLimit;
  final int rxBytes;
  final int txBytes;

  AppResources({
    this.cpuPercent,
    this.cpuLimit,
    this.memoryPercent,
    this.memoryBytes = 0,
    this.memoryLimit = 0,
    this.diskPercent,
    this.diskBytes = 0,
    this.diskLimit = 0,
    this.rxBytes = 0,
    this.txBytes = 0,
  });

  factory AppResources.fromJson(Map<String, dynamic> j) => AppResources(
        cpuPercent: (j['cpu_percent'] as num?)?.toDouble(),
        cpuLimit: (j['cpu_limit'] as num?)?.toDouble(),
        memoryPercent: (j['memory_percent'] as num?)?.toDouble(),
        memoryBytes: (j['memory_bytes'] as num?)?.toInt() ?? 0,
        memoryLimit: (j['memory_limit'] as num?)?.toInt() ?? 0,
        diskPercent: (j['disk_percent'] as num?)?.toDouble(),
        diskBytes: (j['disk_bytes'] as num?)?.toInt() ?? 0,
        diskLimit: (j['disk_limit'] as num?)?.toInt() ?? 0,
        rxBytes: (j['rx_bytes'] as num?)?.toInt() ?? 0,
        txBytes: (j['tx_bytes'] as num?)?.toInt() ?? 0,
      );
}

class AppFileInfo {
  final bool exists;
  final int size;
  final bool requirements;

  AppFileInfo({
    this.exists = false,
    this.size = 0,
    this.requirements = false,
  });

  factory AppFileInfo.fromJson(Map<String, dynamic> j) => AppFileInfo(
        exists: j['exists'] == true,
        size: (j['size'] as num?)?.toInt() ?? 0,
        requirements: j['requirements'] == true,
      );
}
