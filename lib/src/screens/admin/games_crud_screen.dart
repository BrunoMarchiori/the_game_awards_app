import 'package:flutter/material.dart';
import '../../db/db.dart';

class GamesCrudScreen extends StatefulWidget {
  const GamesCrudScreen({super.key});

  @override
  State<GamesCrudScreen> createState() => _GamesCrudScreenState();
}

class _GamesCrudScreenState extends State<GamesCrudScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = AppDatabase.instance.db;
    return db.query('game', orderBy: 'name');
  }

  Future<void> _addOrEdit({Map<String, dynamic>? game}) async {
    final nameCtrl = TextEditingController(text: game?['name'] as String?);
    final descCtrl = TextEditingController(text: game?['description'] as String?);
    final dateCtrl = TextEditingController(text: game?['release_date'] as String?);
    final formKey = GlobalKey<FormState>();
    final isEdit = game != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar jogo' : 'Novo jogo'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => v==null||v.isEmpty?'Informe o nome':null),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição'), validator: (v) => v==null||v.isEmpty?'Informe a descrição':null, maxLines: 3),
                  TextFormField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Data de lançamento (YYYY-MM-DD)'), validator: (v) => v==null||v.isEmpty?'Informe a data':null),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancelar')),
          FilledButton(onPressed: () async { if(formKey.currentState!.validate()){ final db=AppDatabase.instance.db; if(isEdit){ await db.update('game', {'name':nameCtrl.text.trim(),'description':descCtrl.text.trim(),'release_date':dateCtrl.text.trim()}, where:'id=?', whereArgs:[game!['id']]); } else { await db.insert('game', {'name':nameCtrl.text.trim(),'description':descCtrl.text.trim(),'release_date':dateCtrl.text.trim(),'user_id':1}); } if(context.mounted) Navigator.pop(context,true);} }, child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) setState(() => _future = _load());
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Remover jogo'), content: const Text('Tem certeza?'), actions:[TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancelar')), FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Remover'))]));
    if (ok == true) {
      final db = AppDatabase.instance.db;
      await db.delete('game', where: 'id=?', whereArgs: [id]);
      setState(() => _future = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Jogos')),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=>_addOrEdit(), icon: const Icon(Icons.add), label: const Text('Novo')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhum jogo cadastrado'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final g = items[i];
              return ListTile(
                leading: const Icon(Icons.sports_esports),
                title: Text(g['name'] as String),
                subtitle: Text('Lançamento: ${g['release_date']}\n${g['description']}'),
                isThreeLine: true,
                trailing: Wrap(spacing: 8, children: [
                  IconButton(onPressed: ()=>_addOrEdit(game: g), icon: const Icon(Icons.edit)),
                  IconButton(onPressed: ()=>_delete(g['id'] as int), icon: const Icon(Icons.delete), color: Colors.red),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
