import 'package:flutter/foundation.dart';
import '../db/db.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final int role; // 0=admin, 1=user
  const AuthUser({required this.id, required this.name, required this.email, required this.role});
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isLogged => _user != null;
  bool get isAdmin => _user?.role == 0;

  Future<bool> login(String email, String password) async {
    final rows = await AppDatabase.instance.db.query('user', where: 'email=? AND password=?', whereArgs: [email, password], limit: 1);
    if (rows.isEmpty) return false;
    final u = rows.first;
    _user = AuthUser(id: u['id'] as int, name: u['name'] as String, email: u['email'] as String, role: u['role'] as int);
    notifyListeners();
    return true;
  }

  Future<bool> register({required String name, required String email, required String password, required bool isAdmin}) async {
    try {
      final id = await AppDatabase.instance.db.insert('user', {
        'name': name,
        'email': email,
        'password': password,
        'role': isAdmin ? 0 : 1,
      });
      _user = AuthUser(id: id, name: name, email: email, role: isAdmin ? 0 : 1);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void loginAsGuest() {
    _user = null; // guest = null user
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
