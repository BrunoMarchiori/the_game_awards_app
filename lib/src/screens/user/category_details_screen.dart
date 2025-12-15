import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/db.dart';
import '../../providers/auth_provider.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const CategoryDetailsScreen({super.key, required this.category});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  late Future<_CategoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CategoryData> _load() async {
    final db = AppDatabase.instance.db;
    final catId = widget.category['id'] as int;
    final rows = await db.rawQuery('''
      SELECT cg.id AS assoc_id, g.id AS game_id, g.name,
             (SELECT COUNT(*) FROM user_vote uv WHERE uv.vote_game_id = cg.id) AS votes
      FROM category_game cg
      JOIN game g ON g.id = cg.game_id
      WHERE cg.category_id = ?
      ORDER BY votes DESC, g.name ASC
    ''', [catId]);

    int? userVoteAssocId;
    // get current user vote
    final auth = mounted ? context.read<AuthProvider>() : null;
    if (auth != null && auth.isLogged) {
      final x = await db.query('user_vote', where: 'user_id=? AND category_id=?', whereArgs: [auth.user!.id, catId], limit: 1);
      if (x.isNotEmpty) userVoteAssocId = x.first['vote_game_id'] as int;
    }
    return _CategoryData(rows: rows, userVoteAssocId: userVoteAssocId);
  }

  Future<void> _toggleVote(int assocId) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLogged) return; // guest can't vote
    final db = AppDatabase.instance.db;
    final catId = widget.category['id'] as int;
    final existing = await db.query('user_vote', where: 'user_id=? AND category_id=?', whereArgs: [auth.user!.id, catId], limit: 1);
    if (existing.isEmpty) {
      await db.insert('user_vote', {'user_id': auth.user!.id, 'category_id': catId, 'vote_game_id': assocId});
    } else {
      final currentAssoc = existing.first['vote_game_id'] as int;
      if (currentAssoc == assocId) {
        // remove vote
        await db.delete('user_vote', where: 'id=?', whereArgs: [existing.first['id']]);
      } else {
        // change vote
        await db.update('user_vote', {'vote_game_id': assocId}, where: 'id=?', whereArgs: [existing.first['id']]);
      }
    }
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canVote = auth.isLogged && auth.user!.role == 1; // common user only
    final isGuest = !auth.isLogged;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category['title'] as String)),
      body: FutureBuilder<_CategoryData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? _CategoryData(rows: [], userVoteAssocId: null);
          if (data.rows.isEmpty) return const Center(child: Text('Nenhum jogo associado.'));
          return ListView.builder(
            itemCount: data.rows.length,
            itemBuilder: (_, i) {
              final r = data.rows[i];
              final assocId = r['assoc_id'] as int;
              final voted = data.userVoteAssocId == assocId;
              return ListTile(
                leading: CircleAvatar(child: Text('${i+1}')),
                title: Text(r['name'] as String),
                subtitle: Text('Votos: ${r['votes']}'),
                trailing: canVote
                    ? IconButton(
                        icon: Icon(voted ? Icons.how_to_vote : Icons.how_to_vote_outlined, color: voted ? Colors.green : null),
                        onPressed: () => _toggleVote(assocId),
                      )
                    : (isGuest ? const Text('Apenas visualização') : null),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryData {
  final List<Map<String, dynamic>> rows;
  final int? userVoteAssocId;
  _CategoryData({required this.rows, required this.userVoteAssocId});
}
