import 'package:flutter/material.dart';
import '../../db/db.dart';
import 'category_details_screen.dart';

class CategoryListScreen extends StatefulWidget {
  final int? openCategoryId;
  const CategoryListScreen({super.key, this.openCategoryId});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppDatabase.instance.db.query('category', orderBy: 'date DESC');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')), 
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhuma categoria cadastrada.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(c['title'] as String),
                subtitle: Text(c['description']?.toString() ?? ''),
                trailing: Text(c['date'] as String),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailsScreen(category: c))),
              );
            },
          );
        },
      ),
    );
  }
}
