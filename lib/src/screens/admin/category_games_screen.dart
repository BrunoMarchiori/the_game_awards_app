import 'package:flutter/material.dart';
import '../../db/db.dart';
import 'package:sqflite_common/sqlite_api.dart' show ConflictAlgorithm;
import 'package:sqflite_common/sqlite_api.dart';

class CategoryGamesScreen extends StatefulWidget {
  const CategoryGamesScreen({super.key});

  @override
  State<CategoryGamesScreen> createState() => _CategoryGamesScreenState();
}

class _CategoryGamesScreenState extends State<CategoryGamesScreen> {
  int? _categoryId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _games = [];
  final Set<int> _selectedGameIds = {};
  List<Map<String, dynamic>> _currentAssoc = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final db = AppDatabase.instance.db;
    final categories = await db.query('category', orderBy: 'date DESC');
    final games = await db.query('game', orderBy: 'name');
    setState(() {
      _categories = categories;
      _games = games;
    });
  }

  Future<void> _loadAssociations() async {
    if (_categoryId == null) return;
    final db = AppDatabase.instance.db;
    final rows = await db.rawQuery('''
      SELECT cg.id, g.id AS game_id, g.name
      FROM category_game cg
      JOIN game g ON g.id = cg.game_id
      WHERE cg.category_id = ?
      ORDER BY g.name
    ''', [_categoryId]);
    setState(() {
      _currentAssoc = rows;
      _selectedGameIds.clear();
    });
  }

  Future<void> _saveSelection() async {
    if (_categoryId == null) return;
    final db = AppDatabase.instance.db;
    for (final gid in _selectedGameIds) {
      await db.insert('category_game', {'category_id': _categoryId, 'game_id': gid}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await _loadAssociations();
  }

  Future<void> _removeAssoc(int assocId) async {
    final db = AppDatabase.instance.db;
    await db.delete('category_game', where: 'id=?', whereArgs: [assocId]);
    await _loadAssociations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Associar Jogos às Categorias')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['title'] as String))).toList(),
              value: _categoryId,
              onChanged: (v) async {
                setState(() => _categoryId = v);
                await _loadAssociations();
              },
            ),
            const SizedBox(height: 12),
            const Text('Selecione jogos para associar:'),
            Expanded(
              child: ListView(
                children: _games.map((g) {
                  final id = g['id'] as int;
                  final selected = _selectedGameIds.contains(id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) { _selectedGameIds.add(id); } else { _selectedGameIds.remove(id); }
                      });
                    },
                    title: Text(g['name'] as String),
                  );
                }).toList(),
              ),
            ),
            Row(
              children: [
                FilledButton.icon(onPressed: _saveSelection, icon: const Icon(Icons.link), label: const Text('Associar selecionados')),
                const SizedBox(width: 16),
                OutlinedButton.icon(onPressed: (){ setState(()=>_selectedGameIds.clear()); }, icon: const Icon(Icons.clear), label: const Text('Limpar seleção')),
              ],
            ),
            const Divider(height: 32),
            const Text('Associações atuais:'),
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
