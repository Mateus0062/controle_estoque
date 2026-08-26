import 'package:flutter/material.dart';
import '../modelos/movimentacao.dart';
import '../servicos/firestore_servico.dart';

class HistoricoTab extends StatelessWidget {
  const HistoricoTab({super.key});
  @override Widget build(BuildContext context) {
    final service = FirestoreServico();
    return StreamBuilder<List<Movimentacao>>(stream: service.listarMovimentacoes(), builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final movimentos = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Histórico de movimentações', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), Text('Entradas e saídas registradas no estoque.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 22),
        if (movimentos.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [const Icon(Icons.history_rounded, size: 52), const SizedBox(height: 12), const Text('Nenhuma movimentação registrada.', style: TextStyle(fontWeight: FontWeight.w700))])))
        else ...movimentos.map((m) => _MovimentoCard(movimento: m)),
      ]);
    });
  }
}

class _MovimentoCard extends StatelessWidget {
  final Movimentacao movimento; const _MovimentoCard({required this.movimento});
  @override Widget build(BuildContext context) {
    final entrada = movimento.tipo == TipoMovimentacao.entrada;
    final color = entrada ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), leading: CircleAvatar(backgroundColor: color.withValues(alpha: .10), child: Icon(entrada ? Icons.south_west_rounded : Icons.north_east_rounded, color: color)), title: Text(movimento.produtoNome, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${entrada ? 'Entrada' : 'Saída'} • ${_data(movimento.data)}\nResponsável: ${movimento.usuarioEmail}'), trailing: Text('${entrada ? '+' : '-'}${movimento.quantidade}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800))));
  }
}
String _data(DateTime? date) { if (date == null) return 'Data pendente'; return '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}'; }
