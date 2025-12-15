import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();

  Database? _db;
  Database get db => _db!;

  Future<void> init() async {
    final dbPath = p.join(Directory.current.path, 'award.db');
    _db = await databaseFactoryFfi.openDatabase(dbPath, options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    ));
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE user(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role INTEGER NOT NULL
);
''');

    await db.execute('''
CREATE TABLE genre(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);
''');

    await db.execute('''
CREATE TABLE game(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  release_date TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE game_genre(
  game_id INTEGER NOT NULL,
  genre_id INTEGER NOT NULL,
  PRIMARY KEY(game_id, genre_id),
  FOREIGN KEY(game_id) REFERENCES game(id) ON DELETE CASCADE,
  FOREIGN KEY(genre_id) REFERENCES genre(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE category(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  date TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE category_game(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  game_id INTEGER NOT NULL,
  UNIQUE(category_id, game_id),
  FOREIGN KEY(category_id) REFERENCES category(id) ON DELETE CASCADE,
  FOREIGN KEY(game_id) REFERENCES game(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE user_vote(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  vote_game_id INTEGER NOT NULL,
  UNIQUE(user_id, category_id),
  FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE,
  FOREIGN KEY(category_id) REFERENCES category(id) ON DELETE CASCADE,
  FOREIGN KEY(vote_game_id) REFERENCES category_game(id) ON DELETE CASCADE
);
''');
  }

  Future<void> _seed(Database db) async {
    // Create a default admin and some genres
    await db.insert('user', {
      'name': 'Admin',
      'email': 'admin@award.app',
      'password': 'admin',
      'role': 0,
    });
    for (final g in ['Action','Adventure','RPG','Strategy','Sports','Indie']) {
      await db.insert('genre', {'name': g});
    }
  }
}
