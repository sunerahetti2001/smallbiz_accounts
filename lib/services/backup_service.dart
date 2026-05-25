import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/sqlite_service.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SqliteService _sqlite = SqliteService();

  static const String _lastBackupKey = 'last_backup_time';
  static const String _autoBackupKey = 'auto_backup_enabled';

  // ---------- helpers ----------
  String get _uid => _auth.currentUser!.uid;

  Future<bool> isOnline() async {
    // Simple connectivity check – you can use connectivity_plus here
    // For now, we'll just try to reach Firestore
    try {
      await _firestore.collection('ping').doc('ping').get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------- profile backup ----------
  Future<void> backupProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('profile')
        .doc('info')
        .set(user.toJson(), SetOptions(merge: true));
  }

  Future<UserModel?> restoreProfile() async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('profile')
        .doc('info')
        .get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  // ---------- transactions backup ----------
  Future<void> backupTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  Future<void> backupAllTransactions(List<TransactionModel> transactions) async {
    final batch = _firestore.batch();
    final col = _firestore.collection('users').doc(_uid).collection('transactions');
    for (final t in transactions) {
      batch.set(col.doc(t.id), t.toJson());
    }
    await batch.commit();
  }

  Future<List<TransactionModel>> restoreTransactions() async {
    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .get();
    return snap.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
  }

  // ---------- categories backup ----------
  Future<void> backupCategory(CategoryModel category) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('categories')
        .doc(category.id)
        .set(category.toJson());
  }

  Future<void> backupAllCategories(List<CategoryModel> categories) async {
    final batch = _firestore.batch();
    final col = _firestore.collection('users').doc(_uid).collection('categories');
    for (final c in categories) {
      batch.set(col.doc(c.id), c.toJson());
    }
    await batch.commit();
  }

  Future<List<CategoryModel>> restoreCategories() async {
    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('categories')
        .get();
    return snap.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
  }

  // ---------- full backup ----------
  Future<void> backupToCloud() async {
    if (_auth.currentUser == null) return;
    final user = await _sqlite.getUser(id: _uid);
    if (user != null) await backupProfile(user);

    final transactions = await _sqlite.getTransactions(_uid);
    await backupAllTransactions(transactions);

    final categories = await _sqlite.getCategories(_uid);
    await backupAllCategories(categories);

    await _updateLastBackupTime();
  }

  Future<void> backupSingleTransaction(TransactionModel transaction) async {
    if (_auth.currentUser == null) return;
    await backupTransaction(transaction);
    await _updateLastBackupTime();
  }

  Future<void> backupSingleCategory(CategoryModel category) async {
    if (_auth.currentUser == null) return;
    await backupCategory(category);
    await _updateLastBackupTime();
  }

  // ---------- restore ----------
  Future<bool> hasCloudBackup() async {
    if (_auth.currentUser == null) return false;
    try {
      final profileDoc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('profile')
          .doc('info')
          .get(const GetOptions(source: Source.server));
      if (profileDoc.exists) return true;

      final txnSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      if (txnSnap.docs.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  Future<void> restoreFromCloud() async {
    if (_auth.currentUser == null) return;

    // Restore profile
    final profile = await restoreProfile();
    if (profile != null) {
      await _sqlite.saveUser(profile);
    }

    // Restore categories
    final categories = await restoreCategories();
    for (final c in categories) {
      await _sqlite.insertCategory(c, _uid);
    }

    // Restore transactions
    final transactions = await restoreTransactions();
    for (final t in transactions) {
      await _sqlite.insertTransaction(t, _uid);
    }
  }

  // ---------- timestamp & auto backup ----------
  Future<void> _updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final time = prefs.getString(_lastBackupKey);
    if (time != null) return DateTime.parse(time);
    return null;
  }

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }
}