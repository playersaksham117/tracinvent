class DeviceInfo {
  final String deviceName;
  final String machineGuid;
  final String cpuId;
  final String motherboardSerial;
  final String biosSerial;
  final String diskSerial;
  final String osVersion;
  final String fingerprintHash;

  const DeviceInfo({
    required this.deviceName,
    required this.machineGuid,
    required this.cpuId,
    required this.motherboardSerial,
    required this.biosSerial,
    required this.diskSerial,
    required this.osVersion,
    required this.fingerprintHash,
  });

  Map<String, dynamic> toRegistrationMap(String appVersion) => {
        'device_name': deviceName,
        'fingerprint_hash': fingerprintHash,
        'machine_guid': machineGuid,
        'os_version': osVersion,
        'app_version': appVersion,
      };
}

class RegisteredDevice {
  final String id;
  final String deviceName;
  final String fingerprintHash;
  final String osVersion;
  final String appVersion;
  final DateTime activationDate;
  final DateTime lastSeen;
  final bool isActive;

  const RegisteredDevice({
    required this.id,
    required this.deviceName,
    required this.fingerprintHash,
    required this.osVersion,
    required this.appVersion,
    required this.activationDate,
    required this.lastSeen,
    required this.isActive,
  });

  factory RegisteredDevice.fromMap(Map<String, dynamic> map) {
    return RegisteredDevice(
      id: map['id'] as String,
      deviceName: map['device_name'] as String? ?? '',
      fingerprintHash: map['fingerprint_hash'] as String? ?? '',
      osVersion: map['os_version'] as String? ?? '',
      appVersion: map['app_version'] as String? ?? '',
      activationDate: DateTime.tryParse(map['activation_date'] ?? '') ?? DateTime.now(),
      lastSeen: DateTime.tryParse(map['last_seen'] ?? '') ?? DateTime.now(),
      isActive: map['is_active'] as bool? ?? false,
    );
  }
}
