import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? photoUrl;
  final int lastUsedAt;

  const SavedAccount({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.lastUsedAt,
    this.photoUrl,
  });

  SavedAccount copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? photoUrl,
    int? lastUsedAt,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
      'lastUsedAt': lastUsedAt,
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString().toUpperCase(),
      photoUrl: json['photoUrl']?.toString(),
      lastUsedAt: json['lastUsedAt'] is int
          ? json['lastUsedAt'] as int
          : DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class SavedAccountsService {
  static const String _accountsKey = 'saved_accounts_v1';

  static Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_accountsKey) ?? <String>[];

      final accounts = <SavedAccount>[];
      for (final item in raw) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          final account = SavedAccount.fromJson(decoded);
          if (account.uid.isNotEmpty && account.email.isNotEmpty) {
            accounts.add(account);
          }
        } catch (_) {}
      }

      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return accounts;
    } catch (e) {
      debugPrint('SavedAccountsService.getSavedAccounts error: $e');
      return <SavedAccount>[];
    }
  }

  static Future<void> upsertFromLogin({
    required User user,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();

      final role = (userData['role'] ?? '').toString().toUpperCase();
      final account = SavedAccount(
        uid: user.uid,
        email: user.email?.trim() ?? '',
        name: (userData['name'] ?? user.displayName ?? 'User').toString(),
        role: role,
        photoUrl: userData['photoUrl']?.toString(),
        lastUsedAt: DateTime.now().millisecondsSinceEpoch,
      );

      if (account.email.isEmpty) return;

      final index = accounts.indexWhere((a) => a.uid == account.uid);
      if (index >= 0) {
        accounts[index] = accounts[index].copyWith(
          email: account.email,
          name: account.name,
          role: account.role,
          photoUrl: account.photoUrl,
          lastUsedAt: account.lastUsedAt,
        );
      } else {
        accounts.add(account);
      }

      final encoded = accounts.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_accountsKey, encoded);
    } catch (e) {
      debugPrint('SavedAccountsService.upsertFromLogin error: $e');
    }
  }

  static Future<void> removeByUid(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.uid == uid);
      final encoded = accounts.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_accountsKey, encoded);
    } catch (e) {
      debugPrint('SavedAccountsService.removeByUid error: $e');
    }
  }
}
