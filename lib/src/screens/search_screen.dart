import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/db.dart';
import '../providers/auth_provider.dart';
import 'user/category_details_screen.dart';

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
    // Build association-centric list: each entry ties a game to a category it competes in.
    final args = <Object?>[];
    final filters = <String>[];
    // Genre filter narrows games via join
    if (widget.genreId != null) {
      filters.add('EXISTS (SELECT 1 FROM game_genre gg WHERE gg.game_id = g.id AND gg.genre_id = ?)');
      args.add(widget.genreId);
    }
    // Category filter narrows associations
    if (widget.categoryId != null) {
      filters.add('cg.category_id = ?');
      args.add(widget.categoryId);
    }

    // Base query: one row per association
    final rows = await db.rawQuery('''
      SELECT 
        cg.id          AS assoc_id,
        g.id           AS game_id,
        g.name         AS game_name,
        g.release_date AS release_date,
        c.id           AS category_id,
        c.title        AS category_title,
        (SELECT COUNT(*) FROM user_vote uv WHERE uv.vote_game_id = cg.id) AS votes
      FROM category_game cg
      JOIN game g ON g.id = cg.game_id
      JOIN category c ON c.id = cg.category_id
      ${filters.isEmpty ? '' : 'WHERE ' + filters.join(' AND ')}
      ORDER BY c.title ASC, g.name ASC
    ''', args);

    // Position filter: keep only N-th by votes within each category (and within genre subset if applied)
    if (widget.position != null) {
      final pos = widget.position!;
      // group rows by category
      final byCat = <int, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final cid = r['category_id'] as int;
        (byCat[cid] ??= []).add(r);
      }
      final filtered = <Map<String, dynamic>>[];
      for (final entry in byCat.entries) {
        entry.value.sort((a,b){
          final va = (a['votes'] as int?) ?? 0;
          final vb = (b['votes'] as int?) ?? 0;
          if (vb != va) return vb.compareTo(va);
          return (a['game_name'] as String).compareTo(b['game_name'] as String);
        });
        final idx = pos - 1;
        if (idx < entry.value.length) {
          filtered.add(entry.value[idx]);
        }
      }
      return filtered;
    }

    return rows;
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
              final r = items[i];
              final title = r['game_name'] as String;
              final sub = 'Categoria: ${r['category_title']} · Votos: ${r['votes']}';
              return ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(title),
                subtitle: Text(sub),
                onTap: () {
                  final auth = context.read<AuthProvider>();
                  final isCommonUser = auth.isLogged && auth.user!.role == 1;
                  if (isCommonUser) {
                    // Fetch category map to navigate
                    final cat = {
                      'id': r['category_id'],
                      'title': r['category_title'],
                      'description': '',
                      'date': '',
                    };
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CategoryDetailsScreen(category: cat as Map<String, dynamic>),
                    ));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
