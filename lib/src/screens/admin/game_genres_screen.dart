import 'package:flutter/material.dart';
import '../../db/db.dart';
import 'package:sqflite_common/sqlite_api.dart' show ConflictAlgorithm;

class GameGenresScreen extends StatefulWidget {
  const GameGenresScreen({super.key});

  @override
  State<GameGenresScreen> createState() => _GameGenresScreenState();
}

class _GameGenresScreenState extends State<GameGenresScreen> {
  int? _gameId;
  List<Map<String, dynamic>> _games = [];
  List<Map<String, dynamic>> _genres = [];
  final Set<int> _selectedGenreIds = {};
  List<Map<String, dynamic>> _currentAssoc = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final db = AppDatabase.instance.db;
    final games = await db.query('game', orderBy: 'name');
    final genres = await db.query('genre', orderBy: 'name');
    setState(() {
      _games = games;
      _genres = genres;
    });
  }

  Future<void> _loadAssociations() async {
    if (_gameId == null) return;
    final db = AppDatabase.instance.db;
    final rows = await db.rawQuery('''
      SELECT gg.genre_id AS id, ge.name
      FROM game_genre gg
      JOIN genre ge ON ge.id = gg.genre_id
      WHERE gg.game_id = ?
      ORDER BY ge.name
    ''', [_gameId]);
    setState(() {
      _currentAssoc = rows;
      _selectedGenreIds.clear();
    });
  }

  Future<void> _saveSelection() async {
    if (_gameId == null) return;
    final db = AppDatabase.instance.db;
    for (final gid in _selectedGenreIds) {
      await db.insert('game_genre', {'game_id': _gameId, 'genre_id': gid}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await _loadAssociations();
  }

  Future<void> _removeAssoc(int genreId) async {
    if (_gameId == null) return;
    final db = AppDatabase.instance.db;
    await db.delete('game_genre', where: 'game_id=? AND genre_id=?', whereArgs: [_gameId, genreId]);
    await _loadAssociations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Associar Gêneros aos Jogos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Jogo'),
                    items: _games.map((g) => DropdownMenuItem(value: g['id'] as int, child: Text(g['name'] as String))).toList(),
                    value: _gameId,
                    onChanged: (v) async { setState(() => _gameId = v); await _loadAssociations(); },
                  ),
                ),
                IconButton(
                  tooltip: 'Limpar jogo',
                  onPressed: () => setState(() { _gameId = null; _currentAssoc = []; _selectedGenreIds.clear(); }),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Selecione gêneros para associar:'),
            Expanded(
              child: ListView(
                children: _genres.map((ge) {
                  final id = ge['id'] as int;
                  final selected = _selectedGenreIds.contains(id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) { _selectedGenreIds.add(id); } else { _selectedGenreIds.remove(id); }
                      });
                    },
                    title: Text(ge['name'] as String),
                  );
                }).toList(),
              ),
            ),
            Row(
              children: [
                FilledButton.icon(onPressed: _saveSelection, icon: const Icon(Icons.link), label: const Text('Associar selecionados')),
                const SizedBox(width: 16),
                OutlinedButton.icon(onPressed: (){ setState(()=>_selectedGenreIds.clear()); }, icon: const Icon(Icons.clear), label: const Text('Limpar seleção')),
              ],
            ),
            const Divider(height: 32),
            const Text('Gêneros associados ao jogo:'),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _currentAssoc.length,
                itemBuilder: (_, i){
                  final a = _currentAssoc[i];
                  return ListTile(
                    title: Text(a['name'] as String),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=>_removeAssoc(a['id'] as int)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
