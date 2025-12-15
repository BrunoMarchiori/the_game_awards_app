import 'package:flutter/material.dart';
import '../db/db.dart';

class SearchScreen extends StatefulWidget {
  final int? categoryId;
  final int? genreId;
  final int? position; // 1,2,3
  const SearchScreen({super.key, this.categoryId, this.genreId, this.position});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _search();
  }

  Future<List<Map<String, dynamic>>> _search() async {
    final db = AppDatabase.instance.db;

    // Base: games with optional genre filter
    final where = <String>[];
    final args = <Object?>[];
    if (widget.genreId != null) {
      // filter games having genre
      where.add('g.id IN (SELECT gg.game_id FROM game_genre gg WHERE gg.genre_id = ?)');
      args.add(widget.genreId);
    }
    final baseGames = await db.rawQuery('''
      SELECT g.id, g.name, g.release_date FROM game g
      ${where.isEmpty ? '' : 'WHERE ' + where.join(' AND ')}
      ORDER BY g.name
    ''', args);

    // If category filter provided, only consider those associated to selected category
    List<Map<String, dynamic>> games = baseGames;
    if (widget.categoryId != null) {
      final ids = await db.rawQuery('SELECT g.id FROM category_game cg JOIN game g ON g.id=cg.game_id WHERE cg.category_id=?', [widget.categoryId]);
      final idset = ids.map((e) => e['id'] as int).toSet();
      games = games.where((g) => idset.contains(g['id'] as int)).toList();
    }

    // If position filter provided (1..3), compute rank within category (or all categories separately) and keep matches
    if (widget.position != null) {
      // Compute per-category top N; if categoryId is null, compute per each category and include matched games
      final pos = widget.position!;
      final categories = widget.categoryId != null
          ? await db.query('category', where: 'id=?', whereArgs: [widget.categoryId])
          : await db.query('category');
      final gameOk = <int>{};
      for (final c in categories) {
        final catId = c['id'] as int;
        // order games in this category by votes desc
        final rows = await db.rawQuery('''
          SELECT g.id, COUNT(uv.id) AS votes
          FROM category_game cg
          JOIN game g ON g.id = cg.game_id
          LEFT JOIN user_vote uv ON uv.vote_game_id = cg.id
          WHERE cg.category_id = ?
          GROUP BY g.id
          ORDER BY votes DESC, g.name ASC
        ''', [catId]);
        if (rows.isEmpty) continue;
        final idx = pos - 1;
        if (idx < rows.length) {
          final gid = rows[idx]['id'] as int;
          gameOk.add(gid);
        }
      }
      games = games.where((g) => gameOk.contains(g['id'] as int)).toList();
    }

    return games;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da busca')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhum jogo encontrado.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final g = items[i];
              return ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(g['name'] as String),
                subtitle: Text('Lançamento: ${g['release_date']}'),
              );
            },
          );
        },
      ),
    );
  }
}
