import 'package:flutter/material.dart';
import '../servicos/firestore_servico.dart';

class CategoriasTab extends StatefulWidget {
  const CategoriasTab({super.key});
  @override State<CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<CategoriasTab> {
  final _service = FirestoreServico();
  final _controller = TextEditingController();

  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _adicionar() async {
    final nome = _controller.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome da categoria.')));
      return;
    }
    try {
      await _service.salvarCategoria(nome);
      _controller.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoria adicionada.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _excluir(String nome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text('A categoria “$nome” será removida da lista. Produtos existentes não serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.excluirCategoria(nome);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _service.listarCategorias(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categorias = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Categorias', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Organize seus produtos por categorias.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 550) {
                      return Column(children: [
                        TextField(controller: _controller, onSubmitted: (_) => _adicionar(), decoration: const InputDecoration(labelText: 'Nova categoria', prefixIcon: Icon(Icons.category_outlined))),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _adicionar, icon: const Icon(Icons.add), label: const Text('Adicionar'))),
                      ]);
                    }
                    return Row(children: [
                      Expanded(child: TextField(controller: _controller, onSubmitted: (_) => _adicionar(), decoration: const InputDecoration(labelText: 'Nova categoria', prefixIcon: Icon(Icons.category_outlined)))),
                      const SizedBox(width: 12),
                      FilledButton.icon(onPressed: _adicionar, icon: const Icon(Icons.add), label: const Text('Adicionar')),
                    ]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (categorias.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(36), child: Column(children: [const Icon(Icons.category_outlined, size: 50), const SizedBox(height: 12), const Text('Nenhuma categoria cadastrada.', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('Você também pode criar uma categoria durante o cadastro de um produto.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))])))
            else
              ...categorias.map((nome) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.category_rounded)),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: IconButton(tooltip: 'Excluir categoria', onPressed: () => _excluir(nome), icon: const Icon(Icons.delete_outline_rounded)),
                ),
              )),
          ],
        );
      },
    );
  }
}
