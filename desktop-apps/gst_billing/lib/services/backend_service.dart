/// Backend Service
/// Manages the Python FastAPI backend process lifecycle
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BackendService {
  static const String _backendUrl = 'http://127.0.0.1:8000';
  static const String _healthEndpoint = '/api/health';
  
  static Process? _backendProcess;
  static bool _isStarting = false;
  
  /// Start the backend server
  static Future<bool> startBackend() async {
    // If already running, don't start again
    if (_backendProcess != null) {
      return await isBackendRunning();
    }
    
    if (_isStarting) {
      // Wait for the ongoing startup to complete
      await Future.delayed(const Duration(seconds: 2));
      return await isBackendRunning();
    }
    
    _isStarting = true;
    
    try {
      // Find the backend directory
      final backendDir = await _getBackendDirectory();
      
      if (backendDir == null) {
        print('ERROR: Could not find backend directory');
        _isStarting = false;
        return false;
      }
      
      print('Starting backend from: $backendDir');
      
      // Start the backend process
      _backendProcess = await Process.start(
        'python',
        ['main.py'],
        workingDirectory: backendDir,
      );
      
      // Listen to stdout and stderr
      _backendProcess!.stdout.transform(utf8.decoder).listen((output) {
        print('[BACKEND] $output');
      });
      
      _backendProcess!.stderr.transform(utf8.decoder).listen((error) {
        print('[BACKEND ERROR] $error');
      });
      
      // Wait for backend to be ready
      await _waitForBackendReady(maxAttempts: 30, delaySeconds: 1);
      
      _isStarting = false;
      return true;
    } catch (e) {
      print('ERROR starting backend: $e');
      _isStarting = false;
      _backendProcess = null;
      return false;
    }
  }
  
  /// Stop the backend server gracefully
  static Future<bool> stopBackend() async {
    if (_backendProcess == null) {
      return true;
    }
    
    try {
      print('Stopping backend...');
      
      // Try graceful shutdown first
      _backendProcess!.kill();
      
      // Wait for process to exit
      final exitCode = await _backendProcess!.exitCode;
      print('Backend process exited with code: $exitCode');
      
      _backendProcess = null;
      return true;
    } catch (e) {
      print('ERROR stopping backend: $e');
      _backendProcess = null;
      return false;
    }
  }
  
  /// Check if backend is running and responding
  static Future<bool> isBackendRunning() async {
    try {
      if (_backendProcess == null) {
        return false;
      }
      
      final response = await http.get(
        Uri.parse('$_backendUrl$_healthEndpoint'),
      ).timeout(const Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Wait for backend to be ready (health check)
  static Future<bool> _waitForBackendReady({
    int maxAttempts = 30,
    int delaySeconds = 1,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await http.get(
          Uri.parse('$_backendUrl$_healthEndpoint'),
        ).timeout(const Duration(seconds: 2));
        
        if (response.statusCode == 200) {
          print('Backend is ready!');
          return true;
        }
      } catch (e) {
        // Not ready yet
        if (i == maxAttempts - 1) {
          print('Backend failed to start after ${maxAttempts * delaySeconds} seconds');
          return false;
        }
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    
    return false;
  }
  
  /// Get the backend directory path
  static Future<String?> _getBackendDirectory() async {
    try {
      // Get the base directory of the application
      final executablePath = Platform.resolvedExecutable;
      final appDir = Directory(executablePath).parent.parent.parent;
      
      // Try to find backend in common locations
      final backendPaths = [
        // Development: ../backend (relative to lib)
        'backend',
        // Relative to app root
        '${appDir.path}/backend',
        // Check if we're in the project root
        '${Directory.current.path}/backend',
      ];
      
      for (final path in backendPaths) {
        final backendDir = Directory(path);
        if (await backendDir.exists()) {
          final mainFile = File('${backendDir.path}/main.py');
          if (await mainFile.exists()) {
            return backendDir.absolute.path;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('ERROR finding backend directory: $e');
      return null;
    }
  }
  
  /// Get backend process information
  static String getBackendStatus() {
    if (_backendProcess == null) {
      return 'Backend is not running';
    }
    
    return 'Backend is running (PID: ${_backendProcess!.pid})';
  }
}

