import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/db.dart';
import '../providers/auth_provider.dart';
import 'admin/categories_crud_screen.dart';
import 'admin/games_crud_screen.dart';
import 'admin/category_games_screen.dart';
import 'user/category_list_screen.dart';
import 'user/category_details_screen.dart';
import 'search_screen.dart';
import 'admin/game_genres_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedCategoryId;
  int? _selectedGenreId;
  int? _selectedPosition; // 1,2,3
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _genres = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final db = AppDatabase.instance.db;
    final categories = await db.query('category', orderBy: 'date DESC');
    final genres = await db.query('genre', orderBy: 'name');
    setState(() {
      _categories = categories;
      _genres = genres;
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final title = isAdmin ? 'Dashboard (Admin)' : 'Dashboard';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Deslogar'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 8,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Categoria (todas/inativas inclusas)'),
                  hint: const Text('Todas'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(c['title'] as String),
                  )).toList(),
                  value: _selectedCategoryId,
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
              IconButton(
                tooltip: 'Limpar categoria',
                onPressed: () => setState(() => _selectedCategoryId = null),
                icon: const Icon(Icons.clear),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Gênero'),
                  hint: const Text('Todos'),
                  items: _genres.map((g) => DropdownMenuItem(
                    value: g['id'] as int,
                    child: Text(g['name'] as String),
                  )).toList(),
                  value: _selectedGenreId,
                  onChanged: (v) => setState(() => _selectedGenreId = v),
                ),
              ),
              IconButton(
                tooltip: 'Limpar gênero',
                onPressed: () => setState(() => _selectedGenreId = null),
                icon: const Icon(Icons.clear),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Posição (Top 3 por categoria)'),
                  hint: const Text('Todas'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Primeiro lugar')),
                    DropdownMenuItem(value: 2, child: Text('Segundo lugar')),
                    DropdownMenuItem(value: 3, child: Text('Terceiro lugar')),
                  ],
                  value: _selectedPosition,
                  onChanged: (v) => setState(() => _selectedPosition = v),
                ),
              ),
              IconButton(
                tooltip: 'Limpar posição',
                onPressed: () => setState(() => _selectedPosition = null),
                icon: const Icon(Icons.clear),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      categoryId: _selectedCategoryId,
                      genreId: _selectedGenreId,
                      position: _selectedPosition,
                    ),
                  ));
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar jogos'),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesCrudScreen())),
                      icon: const Icon(Icons.sports_esports),
                      label: const Text('Administrar Jogos'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesCrudScreen())),
                      icon: const Icon(Icons.category),
                      label: const Text('Administrar Categorias'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryGamesScreen())),
                      icon: const Icon(Icons.link),
                      label: const Text('Associar Jogos às Categorias'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameGenresScreen())),
                      icon: const Icon(Icons.local_offer),
                      label: const Text('Associar Gêneros aos Jogos'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(isAdmin ? 'Categorias ativas (visualização rápida)' : 'Categorias ativas', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _ActiveCategoriesList(),
        ],
      ),
    );
  }
}

class _ActiveCategoriesList extends StatefulWidget {
  const _ActiveCategoriesList();

  @override
  State<_ActiveCategoriesList> createState() => _ActiveCategoriesListState();
}

class _ActiveCategoriesListState extends State<_ActiveCategoriesList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = AppDatabase.instance.db;
    final rows = await db.query('category', orderBy: 'date DESC');
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    return rows.where((c) {
      try {
        final d = DateTime.parse(c['date'] as String);
        // ativo se hoje <= data (validade)
        return !d.isBefore(DateTime(now.year, now.month, now.day));
      } catch (_) {
        // fallback: parse by format
        try { final d = fmt.parse(c['date'] as String); return !d.isBefore(DateTime(now.year, now.month, now.day)); } catch (_) {}
        return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text('Nenhuma categoria ativa.');
        }
        return Column(
          children: items.map((c) => ListTile(
            title: Text(c['title'] as String),
            subtitle: Text(c['description']?.toString() ?? ''),
            trailing: Text(c['date'] as String),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryDetailsScreen(category: c),
            )),
          )).toList(),
        );
      },
    );
  }
}
