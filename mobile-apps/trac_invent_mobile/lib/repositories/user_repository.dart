import '../models/user.dart';
import 'base_repository.dart';

/// Repository for user operations
class UserRepository extends BaseRepository<User> {
  @override
  String get tableName => 'users';
  
  @override
  User fromMap(Map<String, dynamic> map) => User.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(User item) => item.toMap();
  
  /// Get user by username
  Future<User?> getByUsername(String username) async {
    final users = await getAll(
      where: 'username = ?',
      whereArgs: [username],
    );
    return users.isEmpty ? null : users.first;
  }
  
  /// Authenticate user
  Future<User?> authenticate(String username, String passwordHash) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    
    // Update last login
    final user = User.fromMap(maps.first);
    await database.update(
      tableName,
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    
    return user;
  }
  
  /// Get active users
  Future<List<User>> getActiveUsers() async {
    return getAll(
      where: 'is_active = 1',
      orderBy: 'username ASC',
    );
  }
  
  /// Get users by role
  Future<List<User>> getByRole(String role) async {
    return getAll(
      where: 'role = ? AND is_active = 1',
      whereArgs: [role],
      orderBy: 'username ASC',
    );
  }
  
  /// Update password
  Future<int> updatePassword(String userId, String newPasswordHash) async {
    final database = await db;
    return database.update(
      tableName,
      {
        'password_hash': newPasswordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  /// Deactivate user
  Future<int> deactivate(String userId) async {
    final database = await db;
    return database.update(
      tableName,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
