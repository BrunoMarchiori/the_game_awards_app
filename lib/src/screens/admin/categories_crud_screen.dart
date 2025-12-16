import 'package:flutter/material.dart';
import '../../db/db.dart';

class CategoriesCrudScreen extends StatefulWidget {
  const CategoriesCrudScreen({super.key});

  @override
  State<CategoriesCrudScreen> createState() => _CategoriesCrudScreenState();
}

class _CategoriesCrudScreenState extends State<CategoriesCrudScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = AppDatabase.instance.db;
    return db.query('category', orderBy: 'date DESC');
  }

  Future<void> _addOrEdit({Map<String, dynamic>? cat}) async {
    final titleCtrl = TextEditingController(text: cat?['title'] as String?);
    final descCtrl = TextEditingController(text: cat?['description'] as String?);
    final dateCtrl = TextEditingController(text: cat?['date'] as String?);
    final formKey = GlobalKey<FormState>();
    final isEdit = cat != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar categoria' : 'Nova categoria'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título'), validator: (v)=>v==null||v.isEmpty?'Informe o título':null),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')), 
                  TextFormField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Validade (YYYY-MM-DD)'), validator: (v)=>v==null||v.isEmpty?'Informe a data':null),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancelar')),
          FilledButton(onPressed: () async { if(formKey.currentState!.validate()){ final db=AppDatabase.instance.db; if(isEdit){ await db.update('category', {'title':titleCtrl.text.trim(),'description':descCtrl.text.trim(),'date':dateCtrl.text.trim()}, where:'id=?', whereArgs:[cat!['id']]); } else { await db.insert('category', {'title':titleCtrl.text.trim(),'description':descCtrl.text.trim(),'date':dateCtrl.text.trim(),'user_id':1}); } if(context.mounted) Navigator.pop(context,true);} }, child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) setState(() { _future = _load(); });
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Remover categoria'), content: const Text('Tem certeza?'), actions:[TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancelar')), FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Remover'))]));
    if (ok == true) {
      final db = AppDatabase.instance.db;
      await db.delete('category', where: 'id=?', whereArgs: [id]);
      setState(() { _future = _load(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Categorias')),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=>_addOrEdit(), icon: const Icon(Icons.add), label: const Text('Nova')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhuma categoria cadastrada'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(c['title'] as String),
                subtitle: Text('Validade: ${c['date']}\n${c['description'] ?? ''}'),
                isThreeLine: true,
                trailing: Wrap(spacing: 8, children: [
                  IconButton(onPressed: ()=>_addOrEdit(cat: c), icon: const Icon(Icons.edit)),
                  IconButton(onPressed: ()=>_delete(c['id'] as int), icon: const Icon(Icons.delete), color: Colors.red),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
