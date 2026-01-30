# TracInvent Update Server Setup Guide

## Overview

TracInvent includes an automated update system that checks for new versions, downloads updates, and allows one-click installation. This guide explains how to set up and configure the update server.

## Architecture

```
┌─────────────┐          HTTP GET         ┌──────────────┐
│             │ ──────────────────────────>│              │
│  TracInvent │                            │ Update Server│
│    Client   │<─────────────────────────  │   (HTTPS)    │
│             │   JSON Update Info         │              │
└─────────────┘                            └──────────────┘
       │                                           │
       │ Download Update                          │
       │<─────────────────────────────────────────┤
       │         .exe installer                   │
       │                                           │
       v                                           │
 ┌──────────┐                                     │
 │Verify SHA │                                     │
 │  Checksum │                                     │
 └──────────┘                                     │
       │                                           │
       v                                           │
 ┌──────────┐                                     │
 │  Install │                                     │
 │  Update  │                                     │
 └──────────┘                                     │
                                                   │
                                            ┌──────┴────────┐
                                            │               │
                                            │  CDN/Storage  │
                                            │  - .exe files │
                                            │  - Checksums  │
                                            │               │
                                            └───────────────┘
```

## Update Server Requirements

### 1. Server Endpoint

The update server must provide a REST API endpoint that returns update information:

**Endpoint:** `GET /api/updates/latest`  
**Query Parameters:**
- `platform`: `windows` | `macos` | `linux`
- `currentVersion`: Current app version (e.g., `1.0.0`)

**Response Format (JSON):**
```json
{
  "version": "1.2.0",
  "downloadUrl": "https://yourdomain.com/downloads/tracinvent-1.2.0-windows.exe",
  "fileSize": 52428800,
  "releaseDate": "2024-01-15T10:30:00Z",
  "releaseNotes": "## What's New\n\n- Feature 1: Description\n- Feature 2: Description\n- Bug fixes and improvements",
  "isRequired": false,
  "checksum": "a3f5b1c8d9e2f4a7b6c5d8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1"
}
```

### 2. Response Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Semantic version (e.g., "1.2.0") |
| `downloadUrl` | string | Yes | Direct download URL for installer |
| `fileSize` | integer | Yes | File size in bytes |
| `releaseDate` | string | Yes | ISO 8601 date format |
| `releaseNotes` | string | Yes | Markdown-formatted release notes |
| `isRequired` | boolean | Yes | If true, user cannot dismiss update |
| `checksum` | string | Yes | SHA256 checksum of installer file |

### 3. File Hosting

Host installer files on:
- AWS S3 with CloudFront
- Azure Blob Storage with CDN
- Google Cloud Storage
- Self-hosted with nginx/Apache
- GitHub Releases

**Important:** Files must be directly downloadable (no redirects or authentication required).

## Configuration

### Update Service Configuration

Edit `lib/services/update_service.dart`:

```dart
class UpdateService {
  // CONFIGURE THIS: Your update server URL
  static const String updateServerUrl = 'https://your-domain.com/api/updates/latest';
  
  // Optional: Add authentication if needed
  static const String apiKey = 'your-api-key';
  
  // ...rest of the code
}
```

### Building the Installer

1. **Build the Flutter App:**
   ```bash
   flutter build windows --release
   ```

2. **Create Windows Installer using Inno Setup:**

Create `installer.iss`:
```inno
#define MyAppName "TracInvent"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company"
#define MyAppExeName "tracinvent.exe"

[Setup]
AppId={{YOUR-UNIQUE-GUID}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=tracinvent-{#MyAppVersion}-windows
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
SetupIconFile=assets\icons\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
```

3. **Compile Installer:**
   ```bash
   iscc installer.iss
   ```

4. **Generate Checksum:**
   ```bash
   # PowerShell
   Get-FileHash -Algorithm SHA256 .\output\tracinvent-1.0.0-windows.exe | Select-Object -ExpandProperty Hash

   # Linux/macOS
   shasum -a 256 tracinvent-1.0.0-windows.exe
   ```

## Example Server Implementations

### Option 1: Node.js + Express

```javascript
const express = require('express');
const app = express();

const releases = {
  windows: {
    version: '1.2.0',
    downloadUrl: 'https://cdn.yourdomain.com/tracinvent-1.2.0-windows.exe',
    fileSize: 52428800,
    releaseDate: '2024-01-15T10:30:00Z',
    releaseNotes: `## What's New\n\n- Feature 1\n- Feature 2\n- Bug fixes`,
    isRequired: false,
    checksum: 'a3f5b1c8d9e2f4a7b6c5d8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1'
  }
};

app.get('/api/updates/latest', (req, res) => {
  const { platform, currentVersion } = req.query;
  
  const release = releases[platform];
  if (!release) {
    return res.status(404).json({ error: 'Platform not supported' });
  }
  
  // Compare versions
  if (compareVersions(release.version, currentVersion) > 0) {
    return res.json(release);
  }
  
  return res.status(204).send(); // No update available
});

function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);
  
  for (let i = 0; i < 3; i++) {
    if (parts1[i] > parts2[i]) return 1;
    if (parts1[i] < parts2[i]) return -1;
  }
  return 0;
}

app.listen(3000, () => console.log('Update server running on port 3000'));
```

### Option 2: Python + Flask

```python
from flask import Flask, jsonify, request
from datetime import datetime

app = Flask(__name__)

releases = {
    'windows': {
        'version': '1.2.0',
        'downloadUrl': 'https://cdn.yourdomain.com/tracinvent-1.2.0-windows.exe',
        'fileSize': 52428800,
        'releaseDate': '2024-01-15T10:30:00Z',
        'releaseNotes': '## What\'s New\n\n- Feature 1\n- Feature 2\n- Bug fixes',
        'isRequired': False,
        'checksum': 'a3f5b1c8d9e2f4a7b6c5d8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1'
    }
}

@app.route('/api/updates/latest')
def get_latest_update():
    platform = request.args.get('platform')
    current_version = request.args.get('currentVersion')
    
    release = releases.get(platform)
    if not release:
        return jsonify({'error': 'Platform not supported'}), 404
    
    # Compare versions
    if compare_versions(release['version'], current_version) > 0:
        return jsonify(release)
    
    return '', 204  # No update available

def compare_versions(v1, v2):
    parts1 = list(map(int, v1.split('.')))
    parts2 = list(map(int, v2.split('.')))
    
    for i in range(3):
        if parts1[i] > parts2[i]:
            return 1
        if parts1[i] < parts2[i]:
            return -1
    return 0

if __name__ == '__main__':
    app.run(port=3000)
```

### Option 3: Static JSON File (Simple)

Host a static `update.json` file on your CDN:

```json
{
  "windows": {
    "version": "1.2.0",
    "downloadUrl": "https://cdn.yourdomain.com/tracinvent-1.2.0-windows.exe",
    "fileSize": 52428800,
    "releaseDate": "2024-01-15T10:30:00Z",
    "releaseNotes": "## What's New\n\n- Feature 1\n- Feature 2\n- Bug fixes",
    "isRequired": false,
    "checksum": "a3f5b1c8d9e2f4a7b6c5d8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1"
  }
}
```

Update `update_service.dart`:
```dart
static const String updateServerUrl = 'https://cdn.yourdomain.com/update.json';

// Modify checkForUpdates to handle JSON structure
```

### Option 4: GitHub Releases (Free)

Use GitHub Releases as your update server:

1. Create a release on GitHub
2. Upload installer as release asset
3. Use GitHub API to check for updates

```dart
static const String updateServerUrl = 'https://api.github.com/repos/yourusername/tracinvent/releases/latest';

// Parse GitHub API response format
```

## Security Best Practices

1. **HTTPS Only:** Always use HTTPS for update server
2. **Checksum Verification:** Always verify SHA256 checksums
3. **Code Signing:** Sign Windows executables with a certificate
4. **Rate Limiting:** Implement rate limiting on update API
5. **CDN:** Use CDN for faster downloads and DDoS protection
6. **Access Logs:** Monitor update requests for suspicious activity

## Testing the Update System

### 1. Mock Server for Testing

Create a local test server:

```javascript
// test-update-server.js
const express = require('express');
const app = express();

app.get('/api/updates/latest', (req, res) => {
  res.json({
    version: '99.0.0', // High version to trigger update
    downloadUrl: 'http://localhost:3000/test-installer.exe',
    fileSize: 1024,
    releaseDate: new Date().toISOString(),
    releaseNotes: '## Test Update\n\nThis is a test update.',
    isRequired: false,
    checksum: 'test-checksum'
  });
});

app.listen(3000);
```

Update `update_service.dart` temporarily:
```dart
static const String updateServerUrl = 'http://localhost:3000/api/updates/latest';
```

### 2. Test Update Flow

1. Start mock server
2. Run TracInvent
3. Navigate to Settings
4. Click "Check for Updates"
5. Verify update dialog appears
6. Test download (use small test file)
7. Verify checksum validation
8. Test installer launch

## Deployment Checklist

- [ ] Set up production update server
- [ ] Configure HTTPS with valid SSL certificate
- [ ] Upload initial installer to CDN
- [ ] Generate and verify checksums
- [ ] Update `update_service.dart` with production URL
- [ ] Test update flow end-to-end
- [ ] Set up monitoring and alerts
- [ ] Document release process
- [ ] Create backup of update server config
- [ ] Test with different network conditions

## Release Process

1. **Prepare Release:**
   - Update version in `pubspec.yaml`
   - Update `CHANGELOG.md`
   - Write release notes

2. **Build Application:**
   ```bash
   flutter build windows --release
   ```

3. **Create Installer:**
   ```bash
   iscc installer.iss
   ```

4. **Generate Checksum:**
   ```bash
   Get-FileHash -Algorithm SHA256 tracinvent-X.Y.Z-windows.exe
   ```

5. **Upload Files:**
   - Upload installer to CDN
   - Update `update.json` or database with new version info

6. **Test Update:**
   - Install previous version
   - Verify update is detected
   - Complete update installation

7. **Announce Release:**
   - Publish release notes
   - Notify users

## Troubleshooting

### Update Not Detected
- Verify update server URL is correct
- Check server returns valid JSON
- Verify version comparison logic
- Check network connectivity

### Download Fails
- Verify downloadUrl is accessible
- Check file permissions on CDN
- Verify no authentication required
- Check CORS headers if applicable

### Checksum Mismatch
- Regenerate checksum
- Verify file integrity on CDN
- Check for file corruption during upload
- Verify checksum algorithm matches (SHA256)

### Install Fails
- Verify installer has admin privileges
- Check Windows SmartScreen settings
- Verify code signing certificate
- Check installer is not corrupted

## Support

For issues with the update system:
1. Check application logs
2. Verify server is responding
3. Test with curl/Postman
4. Check Windows Event Viewer
5. Contact support with error details

## License

Update system is part of TracInvent application.
