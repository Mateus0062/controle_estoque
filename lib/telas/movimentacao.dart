import 'package:flutter/material.dart';
import '../modelos/movimentacao.dart';
import '../modelos/produto.dart';
import '../servicos/firestore_servico.dart';

class MovimentacaoForm extends StatefulWidget {
  final Produto produto; const MovimentacaoForm({super.key, required this.produto});
  @override State<MovimentacaoForm> createState() => _MovimentacaoFormState();
}
class _MovimentacaoFormState extends State<MovimentacaoForm> {
  final _quantidade = TextEditingController(); final _service = FirestoreServico(); TipoMovimentacao _tipo = TipoMovimentacao.entrada; bool _salvando = false;
  @override void dispose() { _quantidade.dispose(); super.dispose(); }
  Future<void> _salvar() async {
    final q = int.tryParse(_quantidade.text.trim());
    if (q == null || q <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe uma quantidade maior que zero.'))); return; }
    if (_tipo == TipoMovimentacao.saida && q > widget.produto.quantidade) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operação não permitida. Estoque disponível: ${widget.produto.quantidade} unidade(s).'))); return; }
    setState(() => _salvando = true);
    try { await _service.movimentarProduto(produtoId: widget.produto.id, tipo: _tipo, quantidade: q); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimentação registrada com sucesso.'))); Navigator.pop(context); } }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => _salvando = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Movimentar estoque')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Card(child: Padding(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Entrada ou saída', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(widget.produto.nome, style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 22),
    Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.inventory_2_outlined), const SizedBox(width: 12), const Text('Estoque atual', style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text('${widget.produto.quantidade} un.', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])),
    const SizedBox(height: 20), SegmentedButton<TipoMovimentacao>(segments: const [ButtonSegment(value: TipoMovimentacao.entrada, label: Text('Entrada'), icon: Icon(Icons.south_west_rounded)), ButtonSegment(value: TipoMovimentacao.saida, label: Text('Saída'), icon: Icon(Icons.north_east_rounded))], selected: {_tipo}, onSelectionChanged: (s) => setState(() => _tipo = s.first)),
    const SizedBox(height: 18), TextField(controller: _quantidade, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade', prefixIcon: Icon(Icons.numbers_rounded))),
    const SizedBox(height: 12), if (_tipo == TipoMovimentacao.saida) Text('A saída não pode ser maior que o estoque disponível.', style: TextStyle(color: Colors.grey.shade600)),
    const SizedBox(height: 24), SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: _salvando ? null : _salvar, icon: _salvando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded), label: const Text('Registrar movimentação'))),
  ])))))));
}
