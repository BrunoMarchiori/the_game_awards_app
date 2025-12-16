import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart' show ConflictAlgorithm, DatabaseExecutor;

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
      },
    ));
    await _seedFromAttachedSql(_db!);
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

  

  Future<int> _ensureGenre(DatabaseExecutor db, String name) async {
    final row = await db.query('genre', where: 'name = ?', whereArgs: [name], limit: 1);
    if (row.isNotEmpty) return row.first['id'] as int;
    return db.insert('genre', {'name': name});
  }

  Future<void> _seedFromAttachedSql(Database db) async {
    // Idempotent seeding that mirrors the attached SQL content into our schema
    await db.transaction((txn) async {
      // 1) Ensure base users from script (by unique email)
      final users = [
        {'name': 'Teste 1', 'email': 'teste1@teste', 'password': '123456', 'role': 0},
        {'name': 'Teste 2', 'email': 'teste2@teste', 'password': '123456', 'role': 0},
        {'name': 'Teste 3', 'email': 'teste3@teste', 'password': '123456', 'role': 0},
        {'name': 'Teste 4', 'email': 'teste4@teste', 'password': '123456', 'role': 1},
        {'name': 'Teste 5', 'email': 'teste5@teste', 'password': '123456', 'role': 1},
      ];
      for (final u in users) {
        final existing = await txn.query('user', where: 'email = ?', whereArgs: [u['email']], limit: 1);
        if (existing.isEmpty) {
          await txn.insert('user', u);
        }
      }

      Future<int> getUserIdByEmail(String email) async {
        final r = await txn.query('user', where: 'email = ?', whereArgs: [email], limit: 1);
        return r.first['id'] as int;
      }

      // resolve admin user id for FKs on game/category
      final adminId = (await txn.query('user', where: 'email=?', whereArgs: ['admin@award.app'], limit: 1)).isNotEmpty
          ? (await txn.query('user', where: 'email=?', whereArgs: ['admin@award.app'], limit: 1)).first['id'] as int
          : (await txn.query('user', limit: 1)).first['id'] as int;

      // 2) Ensure genres from script (PT names)
      for (final g in ['Aventura','Ação','RPG','Indie','Plataforma','Metroidvania','Rogue Lite','Survival Horror','Mundo Aberto']) {
        await _ensureGenre(txn, g);
      }

      Future<int> ensureGame(String name, String description, String releaseDate) async {
        final trimmed = name.trim();
        final ex = await txn.query('game', where: 'name = ?', whereArgs: [trimmed], limit: 1);
        if (ex.isNotEmpty) return ex.first['id'] as int;
        return txn.insert('game', {
          'user_id': adminId,
          'name': trimmed,
          'description': description,
          'release_date': releaseDate,
        });
      }

      Future<int> ensureCategory(String title, String description, String date) async {
        final ex = await txn.query('category', where: 'title = ?', whereArgs: [title], limit: 1);
        if (ex.isNotEmpty) return ex.first['id'] as int;
        return txn.insert('category', {
          'user_id': adminId,
          'title': title,
          'description': description,
          'date': date,
        });
      }

      Future<int> ensureCategoryGame(int categoryId, int gameId) async {
        final ex = await txn.query('category_game', where: 'category_id=? AND game_id=?', whereArgs: [categoryId, gameId], limit: 1);
        if (ex.isNotEmpty) return ex.first['id'] as int;
        return txn.insert('category_game', {'category_id': categoryId, 'game_id': gameId}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      Future<int> genreIdByName(String name) async {
        final r = await txn.query('genre', where: 'name=?', whereArgs: [name], limit: 1);
        return r.first['id'] as int;
      }

      // 3) Insert games from script
      final games = <Map<String, String>>[
        {
          'name': 'Clair Obscur: Expedition 33',
          'desc': 'Once a year, the Paintress wakes and paints upon her monolith... Expedition 33 is a ground-breaking turn-based RPG...',
          'date': '2025-04-24'
        },
        {
          'name': 'Hades 2',
          'desc': 'The first-ever sequel from Supergiant Games...',
          'date': '2025-09-25'
        },
        {
          'name': 'Hollow Knight: Silksong',
          'desc': 'As the lethal hunter Hornet, adventure through a kingdom ruled by silk and song!...',
          'date': '2025-09-04'
        },
        {
          'name': 'Death Stranding 2: On the Beach',
          'desc': 'Com companheiros ao seu lado, Sam inicia uma nova jornada...',
          'date': '2025-06-26'
        },
        {
          'name': 'Donkey Kong Bananza',
          'desc': 'Donkey Kong Bananza é um jogo eletrônico de plataforma...',
          'date': '2025-07-17'
        },
        {
          'name': 'Kingdom Come: Deliverance II',
          'desc': 'RPG de ação desenvolvido pela Warhorse Studios...',
          'date': '2025-02-04'
        },
      ];

      final gameIds = <String, int>{};
      for (final g in games) {
        gameIds[g['name']!] = await ensureGame(g['name']!, g['desc']!, g['date']!);
      }

      // 4) Map game↔genre as per script
      Future<void> linkGameGenres(String gameName, List<String> genreNames) async {
        final gid = gameIds[gameName]!;
        for (final gn in genreNames) {
          final geid = (await txn.query('genre', where: 'name=?', whereArgs: [gn], limit: 1)).first['id'] as int;
          await txn.insert('game_genre', {'game_id': gid, 'genre_id': geid}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      await linkGameGenres('Clair Obscur: Expedition 33', ['RPG']);
      await linkGameGenres('Hades 2', ['Ação','RPG','Indie']);
      await linkGameGenres('Hollow Knight: Silksong', ['Ação','RPG','Indie']);
      await linkGameGenres('Death Stranding 2: On the Beach', ['Ação']);
      await linkGameGenres('Donkey Kong Bananza', ['Aventura','Ação']);
      await linkGameGenres('Kingdom Come: Deliverance II', ['RPG','Mundo Aberto']);

      // 5) Categories
      final c1 = await ensureCategory(
        'Game of the Year',
        'Recognizing a game that delivers the absolute best experience across all creative and technical fields.',
        '2099-12-11',
      );
      final c2 = await ensureCategory(
        'Best Narrative',
        'For outstanding storytelling and narrative development in a game.',
        '2099-12-11',
      );
      final c3 = await ensureCategory(
        'Best RPG',
        'For the best game designed with rich player character customization and progression, including massively multiplayer experiences.',
        '2099-12-11',
      );
      final c4 = await ensureCategory(
        'Best Family',
        'For the best game appropriate for family play, irrespective of genre or platform.',
        '2099-12-11',
      );
      await ensureCategory(
        'Best Independent Game',
        'For outstanding creative and technical achievement in a game made outside the traditional publisher system.',
        '2099-12-11',
      );
      await ensureCategory(
        'Best Fighting',
        'For the best game designed primarily around head-to-head combat.',
        '2099-12-11',
      );

      // 6) category_game associations from script
      for (final name in [
        'Clair Obscur: Expedition 33',
        'Hades 2',
        'Hollow Knight: Silksong',
        'Death Stranding 2: On the Beach',
        'Donkey Kong Bananza',
        'Kingdom Come: Deliverance II',
      ]) {
        await ensureCategoryGame(c1, gameIds[name]!);
      }
      for (final name in ['Clair Obscur: Expedition 33','Hades 2']) {
        await ensureCategoryGame(c2, gameIds[name]!);
      }

      // 7) user_vote mapping (translate from (user, category, game) to our (user, category, category_game.id))
      Future<int?> findAssocId(int categoryId, int gameId) async {
        final r = await txn.query('category_game', where: 'category_id=? AND game_id=?', whereArgs: [categoryId, gameId], limit: 1);
        if (r.isEmpty) return null;
        return r.first['id'] as int;
      }

      Future<void> upsertVote(String userEmail, int categoryId, String gameName) async {
        final uid = await getUserIdByEmail(userEmail);
        final gid = gameIds[gameName]!;
        final assocId = await findAssocId(categoryId, gid);
        if (assocId == null) return; // association must exist
        final existing = await txn.query('user_vote', where: 'user_id=? AND category_id=?', whereArgs: [uid, categoryId], limit: 1);
        if (existing.isEmpty) {
          await txn.insert('user_vote', {'user_id': uid, 'category_id': categoryId, 'vote_game_id': assocId}, conflictAlgorithm: ConflictAlgorithm.ignore);
        } else {
          await txn.update('user_vote', {'vote_game_id': assocId}, where: 'id=?', whereArgs: [existing.first['id']]);
        }
      }

      await upsertVote('teste4@teste', c1, 'Hollow Knight: Silksong');
      await upsertVote('teste4@teste', c2, 'Clair Obscur: Expedition 33');
      await upsertVote('teste5@teste', c1, 'Clair Obscur: Expedition 33');
      await upsertVote('teste5@teste', c2, 'Hades 2');
    });
  }
}
