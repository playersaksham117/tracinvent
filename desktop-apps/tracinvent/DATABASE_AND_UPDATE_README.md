# Database Cleanup & Auto-Update System

## Overview

TracInvent now includes enterprise-grade database maintenance and automatic update features to keep your application running smoothly and up-to-date.

## Features

### 🗄️ Database Cleanup

Professional database maintenance tools with multiple cleanup strategies:

#### 1. Full Database Reset
- **What it does:** Completely deletes the database and reinitializes with fresh schema
- **Use when:** You want to start completely fresh or fix major data corruption
- **⚠️ Warning:** This action CANNOT be undone. All data will be permanently lost.

#### 2. Clear Selected Tables
Choose which data to remove:
- ✅ **Clear Inventory Items** - Removes all products/items
- ✅ **Clear Stock Records** - Removes stock quantities and locations
- ✅ **Clear Warehouses & Locations** - Removes all warehouse structures
- ✅ **Clear Transactions** - Removes purchase/sale records
- ✅ **Clear Stock Movements** - Removes movement history

**Use when:** You want to remove specific data while keeping other records intact.

#### 3. Optimize Database
- **What it does:** Runs SQLite VACUUM and ANALYZE commands
- **Benefits:**
  - Reduces database file size
  - Improves query performance
  - Reorganizes data for efficiency
- **Use when:** Database feels sluggish or file size is large
- **Safe:** Does not delete any data

### Database Size Monitoring
- Real-time display of current database size
- Formatted in human-readable units (KB, MB, GB)
- Updated after each operation

---

## 🔄 Auto-Update System

Seamless application updates with one-click installation.

### Features

#### Automatic Update Detection
- Checks for updates on app startup (after 3 seconds)
- Background checks don't interrupt workflow
- Manual check available in Settings

#### Smart Update Notifications
- Beautiful update dialog with release information
- Shows version number, file size, and release date
- Displays complete release notes
- "Required Update" badge for critical updates

#### Secure Downloads
- Progress bar with real-time percentage
- Shows download speed (MB/s)
- File size tracking (downloaded/total)
- **SHA256 checksum verification** for security
- Automatic retry on network failures

#### One-Click Installation
- Downloads installer in background
- Verifies file integrity automatically
- Launches installer with elevated privileges
- Gracefully closes application
- User can choose "Later" for optional updates

### Update Settings Panel
Located in **Settings > Application Updates**:

- **Update Status:** Shows if updates are available
- **Last Check Time:** Human-readable format (e.g., "2 hours ago")
- **Manual Check:** Force check for new updates
- **Update Details:** View release notes and download info

---

## How to Use

### Database Cleanup

1. Navigate to **Settings**
2. Scroll to **Database Maintenance** section
3. Click **Database Cleanup** button
4. Choose your cleanup strategy:
   - **Full Database Reset:** Complete wipe and reinitialize
   - **Clear Selected Tables:** Pick specific tables to clear
   - **Optimize Database:** Clean up without deleting data
5. Confirm the action (⚠️ Read warnings carefully!)
6. Wait for operation to complete

### Auto-Updates

#### Automatic Flow:
1. Application checks for updates on startup
2. If update found, dialog appears automatically
3. Review release notes and details
4. Click **Update Now** to download
5. Watch progress bar fill
6. Click **Install Now** when ready
7. Application closes and installer launches

#### Manual Check:
1. Navigate to **Settings**
2. Scroll to **Application Updates** section
3. Click **Check for Updates**
4. Follow automatic flow if update available

---

## Technical Details

### Database Cleanup Implementation

#### Technologies:
- SQLite database
- sqflite_common_ffi for desktop
- Atomic transactions for safety
- File system operations for deletion

#### Cleanup Options:
```dart
await DatabaseCleanupService.cleanDatabase();        // Full reset
await DatabaseCleanupService.clearTables(             // Selective
  clearInventory: true,
  clearStock: true,
  // ... more options
);
await DatabaseCleanupService.optimizeDatabase();      // VACUUM + ANALYZE
final size = await DatabaseCleanupService.getDatabaseSize();
```

#### Safety Features:
- Confirmation dialogs before destructive operations
- Transaction rollback on errors
- Error handling with user notifications
- Database re-initialization after full cleanup

### Auto-Update Implementation

#### Architecture:
```
Client App → Update Server → CDN/Storage
     ↓            ↓              ↓
  Check Ver → JSON Response → Installer
     ↓            ↓              ↓
 Download  → Verify SHA256 → Install
```

#### Technologies:
- HTTP client for API calls
- SHA256 cryptographic verification
- PowerShell for elevated installation
- Provider pattern for state management

#### Security Features:
- HTTPS-only connections
- SHA256 checksum verification
- File integrity validation
- Elevated privilege handling
- Secure temporary file management

#### Update Flow:
1. **Check:** HTTP GET to update server
2. **Compare:** Semantic version comparison (major.minor.patch)
3. **Download:** Stream file with progress callbacks
4. **Verify:** SHA256 checksum validation
5. **Install:** PowerShell elevated launch
6. **Cleanup:** Temporary file removal

---

## Server Setup (For Administrators)

### Update Server Requirements

Your update server must provide a REST API endpoint:

**Endpoint:** `GET /api/updates/latest`

**Query Parameters:**
- `platform`: `windows` | `macos` | `linux`
- `currentVersion`: Current version (e.g., `1.0.0`)

**Response (JSON):**
```json
{
  "version": "1.2.0",
  "downloadUrl": "https://cdn.example.com/tracinvent-1.2.0-windows.exe",
  "fileSize": 52428800,
  "releaseDate": "2024-01-15T10:30:00Z",
  "releaseNotes": "## What's New\n- Feature 1\n- Bug fixes",
  "isRequired": false,
  "checksum": "sha256-hash-here"
}
```

### Configuration

Edit `lib/services/update_service.dart`:
```dart
static const String updateServerUrl = 'https://your-domain.com/api/updates/latest';
```

**📖 Full server setup guide:** See [UPDATE_SERVER_SETUP.md](UPDATE_SERVER_SETUP.md)

---

## File Structure

### Database Cleanup Files:
- `lib/services/database_cleanup_service.dart` - Core cleanup logic
- `lib/widgets/database_cleanup_dialog.dart` - UI dialog component

### Auto-Update Files:
- `lib/models/update_info.dart` - Version and update data models
- `lib/services/update_service.dart` - Update checking and installation
- `lib/providers/update_provider.dart` - State management
- `lib/widgets/update_dialog.dart` - Update notification UI
- `UPDATE_SERVER_SETUP.md` - Server configuration guide

### Integration Points:
- `lib/main.dart` - Update provider and startup check
- `lib/screens/settings_screen.dart` - UI sections for both features

---

## Best Practices

### Database Cleanup:
1. ✅ **Backup First:** Always backup before full reset
2. ✅ **Test Selectively:** Try selective cleanup before full reset
3. ✅ **Regular Optimization:** Run optimize monthly for best performance
4. ❌ **Don't Spam:** Avoid running cleanup repeatedly in short time
5. ❌ **Don't Interrupt:** Let operations complete fully

### Auto-Updates:
1. ✅ **Keep Updated:** Install updates promptly for security
2. ✅ **Read Release Notes:** Review changes before updating
3. ✅ **Stable Network:** Ensure good connection before updating
4. ✅ **Close Work:** Save all work before installing
5. ❌ **Don't Force Close:** Let updates complete naturally

---

## Troubleshooting

### Database Cleanup Issues

**Error: "Database is locked"**
- Close all database connections
- Restart application
- Try again

**Error: "Permission denied"**
- Check file permissions
- Run as administrator
- Check antivirus isn't blocking

**Database not shrinking after optimize:**
- Normal if database is already optimized
- Try full cleanup if severe bloat

### Update Issues

**Update not detected:**
- Check internet connection
- Verify update server URL in code
- Check server is responding
- Try manual check in Settings

**Download fails:**
- Check internet connection
- Verify download URL is accessible
- Check firewall/antivirus settings
- Try again later (server might be busy)

**Checksum verification fails:**
- Server checksum might be incorrect
- File might be corrupted during download
- Try downloading again
- Contact support if persists

**Installer won't launch:**
- Grant administrator privileges
- Check Windows SmartScreen settings
- Verify installer file isn't corrupted
- Check antivirus isn't blocking

---

## Keyboard Shortcuts

- `Ctrl+,` - Open Settings (Windows/Linux)
- `Cmd+,` - Open Settings (macOS)

---

## Privacy & Security

### Database Cleanup:
- ✅ All operations are local
- ✅ No data sent to external servers
- ✅ Complete control over your data
- ✅ Permanent deletion (not recoverable)

### Auto-Updates:
- ✅ HTTPS-only connections
- ✅ Cryptographic checksum verification
- ✅ No tracking or analytics
- ✅ Optional updates (unless marked required)
- ✅ Secure temporary file handling
- ✅ Automatic cleanup after installation

---

## Version History

### Version 1.0.0
- ✨ Initial release with database cleanup
- ✨ Auto-update system implementation
- ✨ Full database reset functionality
- ✨ Selective table clearing
- ✨ Database optimization (VACUUM/ANALYZE)
- ✨ Database size monitoring
- ✨ Update detection on startup
- ✨ Manual update checking
- ✨ Secure download with checksum verification
- ✨ One-click installation
- ✨ Beautiful update dialogs
- ✨ Progress tracking

---

## Support

Need help?
1. Check this README
2. Review [UPDATE_SERVER_SETUP.md](UPDATE_SERVER_SETUP.md) for server issues
3. Check application logs
4. Contact support with:
   - Error messages
   - Steps to reproduce
   - Screenshots if applicable
   - Operating system version

---

## Credits

**Developed for:** TracInvent - Enterprise Inventory Management  
**Features:** Database Maintenance & Auto-Update System  
**Platform:** Windows Desktop (Flutter)  
**License:** Proprietary

---

## Future Enhancements

Planned features:
- 🔄 Automatic backup before database operations
- 🔄 Scheduled database optimization
- 🔄 Update rollback functionality
- 🔄 Delta updates (patch files instead of full installers)
- 🔄 Multiple update channels (stable, beta, dev)
- 🔄 Update history and changelog viewer
- 🔄 Network speed optimization
- 🔄 Pause/resume downloads

---

**Last Updated:** January 2024  
**Version:** 1.0.0
