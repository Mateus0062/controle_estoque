import 'package:flutter/material.dart';
import '../modelos/produto.dart';
import '../servicos/firestore_servico.dart';
import '../utils/formatadores.dart';
import 'movimentacao.dart';
import 'produto_form.dart';

class ProdutosTab extends StatefulWidget { const ProdutosTab({super.key}); @override State<ProdutosTab> createState() => _ProdutosTabState(); }
class _ProdutosTabState extends State<ProdutosTab> {
  final _service = FirestoreServico();
  final _busca = TextEditingController();
  String _filtro = 'Todos';
  String _categoriaFiltro = 'Todas';
  @override void dispose() { _busca.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => StreamBuilder<List<Produto>>(
    stream: _service.listarProdutos(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final todos = snapshot.data!;
      return StreamBuilder<List<String>>(
        stream: _service.listarCategorias(),
        builder: (context, catSnapshot) {
          final categorias = <String>{'Todas', ...?catSnapshot.data, if (_categoriaFiltro != 'Todas') _categoriaFiltro}.toList();
          return AnimatedBuilder(animation: _busca, builder: (context, _) {
            final termo = _busca.text.trim().toLowerCase();
            final produtos = todos.where((p) {
              final matchBusca = termo.isEmpty || p.nome.toLowerCase().contains(termo) || p.codigo.toLowerCase().contains(termo) || p.categoria.toLowerCase().contains(termo);
              final matchFiltro = _filtro == 'Todos' || (_filtro == 'Normal' && p.status == StatusEstoque.normal) || (_filtro == 'Baixo' && p.status == StatusEstoque.baixo) || (_filtro == 'Sem estoque' && p.status == StatusEstoque.semEstoque);
              final matchCategoria = _categoriaFiltro == 'Todas' || p.categoria == _categoriaFiltro;
              return matchBusca && matchFiltro && matchCategoria;
            }).toList();
            return ListView(padding: const EdgeInsets.all(24), children: [
              Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Produtos', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Consulte e administre os produtos cadastrados.')])) , FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutoForm())), icon: const Icon(Icons.add), label: const Text('Novo produto'))]),
              const SizedBox(height: 22),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 420, child: TextField(controller: _busca, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Pesquisar por nome, código ou categoria', prefixIcon: Icon(Icons.search_rounded)))),
                ...['Todos','Normal','Baixo','Sem estoque'].map((f) => ChoiceChip(label: Text(f), selected: _filtro == f, onSelected: (_) => setState(() => _filtro = f))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E8F0))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categoriaFiltro,
                      icon: const Icon(Icons.expand_more_rounded),
                      items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c == 'Todas' ? 'Todas as categorias' : c))).toList(),
                      onChanged: (v) => setState(() => _categoriaFiltro = v ?? 'Todas'),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              if (produtos.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(36), child: Column(children: [const Icon(Icons.inventory_2_outlined, size: 52), const SizedBox(height: 12), const Text('Nenhum produto encontrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(termo.isEmpty ? 'Cadastre seu primeiro produto para começar.' : 'Tente outro termo de pesquisa.', style: TextStyle(color: Colors.grey.shade600))])))
              else ...produtos.map((p) => _ProdutoCard(produto: p, onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProdutoForm(produto: p))), onDelete: () => _excluir(p), onMovimentar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovimentacaoForm(produto: p))))),
            ]);
          });
        },
      );
    },
  );

  Future<void> _excluir(Produto p) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Excluir produto?'), content: Text('Deseja realmente excluir “${p.nome}”? Esta ação não poderá ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
    if (ok != true) return;
    try { await _service.excluirProduto(p.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto excluído com sucesso.'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto; final VoidCallback onEdit, onDelete, onMovimentar;
  const _ProdutoCard({required this.produto, required this.onEdit, required this.onDelete, required this.onMovimentar});
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: LayoutBuilder(builder: (context, c) {
    final compact = c.maxWidth < 650;
    final info = Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(produto.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), _StatusBadge2(status: produto.status)]), const SizedBox(height: 7), Text('${produto.codigo} • ${produto.categoria}', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 8), Text(produto.descricao.isEmpty ? 'Sem descrição' : produto.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700))]));
    final numbers = Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('${produto.quantidade}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const Text('estoque', style: TextStyle(fontSize: 11))])), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatarMoeda(produto.precoVenda), style: const TextStyle(fontWeight: FontWeight.w800)), Text('preço de venda', style: TextStyle(color: Colors.grey.shade600, fontSize: 11))])]);
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Entrada / saída', onPressed: onMovimentar, icon: const Icon(Icons.swap_vert_rounded)), IconButton(tooltip: 'Editar', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Excluir', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded))]);
    return compact ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 14), numbers, const SizedBox(height: 6), actions]) : Row(children: [info, const SizedBox(width: 20), numbers, const SizedBox(width: 10), actions]);
  })));
}

class _StatusBadge2 extends StatelessWidget { final StatusEstoque status; const _StatusBadge2({required this.status}); @override Widget build(BuildContext context) { final c = status == StatusEstoque.normal ? const Color(0xFF16A34A) : status == StatusEstoque.baixo ? const Color(0xFFF59E0B) : const Color(0xFFDC2626); final t = status == StatusEstoque.normal ? 'Normal' : status == StatusEstoque.baixo ? 'Baixo' : 'Sem estoque'; return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: c.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700))); } }
