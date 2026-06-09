import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../models/device_info.dart';

/// Collects Windows hardware identifiers and produces a stable SHA-256 fingerprint.
/// All WMI/Registry queries run via PowerShell to avoid native dependencies.
class HardwareFingerprintService {
  static Future<DeviceInfo> collect() async {
    final machinGuid = await _runPS(
      r"(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid).MachineGuid",
    );
    final cpuId = await _runPS(
      r"(Get-WmiObject -Class Win32_Processor | Select-Object -First 1).ProcessorId",
    );
    final mbSerial = await _runPS(
      r"(Get-WmiObject -Class Win32_BaseBoard | Select-Object -First 1).SerialNumber",
    );
    final biosSerial = await _runPS(
      r"(Get-WmiObject -Class Win32_BIOS | Select-Object -First 1).SerialNumber",
    );
    final diskSerial = await _runPS(
      r"(Get-WmiObject -Class Win32_DiskDrive | Select-Object -First 1).SerialNumber",
    );
    final osVersion = await _runPS(
      r"[System.Environment]::OSVersion.VersionString",
    );
    final deviceName = await _runPS(r"$env:COMPUTERNAME");

    final composite = [machinGuid, cpuId, mbSerial, biosSerial, diskSerial]
        .map((s) => s.trim().toUpperCase())
        .join('|');

    final fingerprintHash =
        sha256.convert(utf8.encode(composite)).toString();

    return DeviceInfo(
      deviceName: deviceName.trim().isNotEmpty ? deviceName.trim() : 'Windows PC',
      machineGuid: machinGuid.trim(),
      cpuId: cpuId.trim(),
      motherboardSerial: mbSerial.trim(),
      biosSerial: biosSerial.trim(),
      diskSerial: diskSerial.trim(),
      osVersion: osVersion.trim(),
      fingerprintHash: fingerprintHash,
    );
  }

  static Future<String> _runPS(String script) async {
    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        stdoutEncoding: const SystemEncoding(),
        stderrEncoding: const SystemEncoding(),
      );
      final out = (result.stdout as String).trim();
      if (out.isEmpty || out.toLowerCase().contains('error')) return 'UNKNOWN';
      return out;
    } catch (_) {
      return 'UNKNOWN';
    }
  }
}
