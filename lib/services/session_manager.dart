import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_center.dart';

class StoredAccount {
  final int userId;
  final String username;
  final String token;
  final String? displayName;
  final DateTime lastUsed;

  const StoredAccount({
    required this.userId,
    required this.username,
    required this.token,
    this.displayName,
    required this.lastUsed,
  });

  StoredAccount copyWith({
    String? token,
    DateTime? lastUsed,
    String? displayName,
  }) {
    return StoredAccount(
      userId: userId,
      username: username,
      token: token ?? this.token,
      displayName: displayName ?? this.displayName,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  String toStorage() => jsonEncode({
        'userId': userId,
        'username': username,
        'token': token,
        'displayName': displayName,
        'lastUsed': lastUsed.toIso8601String(),
      });

  static StoredAccount? fromStorage(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final userId = map['userId'];
      final username = map['username'];
      final token = map['token'];
      final lastUsedStr = map['lastUsed']?.toString();

      if (userId == null ||
          username == null ||
          username.toString().isEmpty ||
          token == null ||
          token.toString().isEmpty ||
          lastUsedStr == null) {
        return null;
      }

      final parsedDate = DateTime.tryParse(lastUsedStr) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return StoredAccount(
        userId: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
        username: username.toString(),
        token: token.toString(),
        displayName: map['displayName']?.toString(),
        lastUsed: parsedDate,
      );
    } catch (_) {
      return null;
    }
  }
}

class SessionManager {
  static const _accountsKey = 'stored_accounts';
  static const _activeAccountKey = 'active_account_id';

  static Future<List<StoredAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountsKey) ?? [];
    final accounts = raw
        .map(StoredAccount.fromStorage)
        .whereType<StoredAccount>()
        .toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return accounts;
  }

  static Future<void> _saveAccounts(List<StoredAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _accountsKey,
      accounts.map((a) => a.toStorage()).toList(),
    );
  }

  static Future<StoredAccount?> getActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt(_activeAccountKey);
    final accounts = await loadAccounts();
    StoredAccount? active;

    if (activeId != null) {
      try {
        active = accounts.firstWhere((a) => a.userId == activeId);
      } catch (_) {}
      active ??= accounts.isNotEmpty ? accounts.first : null;
    }

    if (active != null) return active;

    // Legacy fallback to keep old sessions working if list is empty.
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    final legacyId = prefs.getInt('user_id') ?? 0;
    if (token != null && token.isNotEmpty && username != null) {
      final legacy = StoredAccount(
        userId: legacyId,
        username: username,
        token: token,
        displayName: null,
        lastUsed: DateTime.now(),
      );
      await upsertAccount(legacy, setActive: true);
      return legacy;
    }

    return null;
  }

  static Future<void> upsertAccount(
    StoredAccount account, {
    bool setActive = false,
  }) async {
    final accounts = await loadAccounts();
    accounts.removeWhere(
      (a) =>
          a.userId == account.userId ||
          a.username.toLowerCase() == account.username.toLowerCase(),
    );
    accounts.insert(
      0,
      account.copyWith(lastUsed: DateTime.now()),
    );
    await _saveAccounts(accounts);

    if (setActive) {
      await setActiveAccount(account);
    }
  }

  static Future<void> setActiveAccount(StoredAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', account.token);
    await prefs.setString('username', account.username);
    await prefs.setInt('user_id', account.userId);
    await prefs.setInt(_activeAccountKey, account.userId);

    NotificationCenter.instance.setCurrentUser(
      account.userId.toString(),
      resetHistory: false,
    );

    await upsertAccount(account.copyWith(lastUsed: DateTime.now()));
  }

  static Future<void> removeAccount(int userId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.userId == userId);
    await _saveAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt(_activeAccountKey);
    if (activeId == userId) {
      await clearActiveSession();
    }
  }

  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('user_id');
    await prefs.remove(_activeAccountKey);
    NotificationCenter.instance.clearAll();
  }
}
