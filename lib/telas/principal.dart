import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../modelos/movimentacao.dart';
import '../modelos/produto.dart';
import '../servicos/auth_servico.dart';
import '../servicos/firestore_servico.dart';
import '../utils/formatadores.dart';
import 'categorias.dart';
import 'historico.dart';
import 'produtos.dart';

class Principal extends StatefulWidget {
  const Principal({super.key});
  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int _index = 0;
  final _auth = AuthServico();

  final _titulos = const ['Dashboard', 'Produtos', 'Movimentações', 'Categorias'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onOpenProducts: () => setState(() => _index = 1)),
      const ProdutosTab(),
      const HistoricoTab(),
      const CategoriasTab(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_index], style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Center(child: Text(FirebaseAuth.instance.currentUser?.email ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)))),
          IconButton(tooltip: 'Sair', onPressed: _sair, icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(padding: const EdgeInsets.only(bottom: 22), child: CircleAvatar(radius: 22, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.inventory_2_rounded, color: Theme.of(context).colorScheme.primary))),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: Text('Produtos')),
                  NavigationRailDestination(icon: Icon(Icons.swap_vert_outlined), selectedIcon: Icon(Icons.swap_vert_rounded), label: Text('Movimentações')),
                  NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category_rounded), label: Text('Categorias')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: pages[_index]),
            ])
          : pages[_index],
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: _index, onDestinationSelected: (i) => setState(() => _index = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Produtos'),
        NavigationDestination(icon: Icon(Icons.swap_vert_outlined), selectedIcon: Icon(Icons.swap_vert_rounded), label: 'Histórico'),
        NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category_rounded), label: 'Categorias'),
      ]),
    );
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Sair da conta?'), content: const Text('Você precisará entrar novamente para acessar o estoque.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair'))]));
    if (ok == true) await _auth.logout();
  }
}

class DashboardTab extends StatelessWidget {
  final VoidCallback onOpenProducts;
  const DashboardTab({super.key, required this.onOpenProducts});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreServico();
    return StreamBuilder<List<Produto>>(
      stream: service.listarProdutos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErroEstado(mensagem: snapshot.error.toString());
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final produtos = snapshot.data!;
        final total = produtos.length;
        final baixos = produtos.where((p) => p.status == StatusEstoque.baixo).length;
        final semEstoque = produtos.where((p) => p.status == StatusEstoque.semEstoque).length;
        final valorCusto = produtos.fold<double>(0, (soma, p) => soma + p.quantidade * p.precoCusto);
        final valorVenda = produtos.fold<double>(0, (soma, p) => soma + p.quantidade * p.precoVenda);
        return StreamBuilder<List<String>>(
          stream: service.listarCategorias(),
          builder: (context, categorySnapshot) {
            final categorias = categorySnapshot.data?.length ?? produtos.map((p) => p.categoria).where((c) => c.isNotEmpty).toSet().length;
            return StreamBuilder<List<Movimentacao>>(
              stream: service.listarMovimentacoes(),
              builder: (context, movSnapshot) {
                final movimentos = movSnapshot.data ?? const <Movimentacao>[];
                return RefreshIndicator(onRefresh: () async {}, child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('Visão geral', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Acompanhe a situação do seu estoque em tempo real.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 650 ? 2 : 1;
            return GridView.count(crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.2, children: [
              _StatCard(label: 'Produtos', value: '$total', icon: Icons.inventory_2_rounded, color: const Color(0xFF2563EB)),
              _StatCard(label: 'Estoque baixo', value: '$baixos', icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
              _StatCard(label: 'Sem estoque', value: '$semEstoque', icon: Icons.remove_shopping_cart_rounded, color: const Color(0xFFDC2626)),
              _StatCard(label: 'Categorias', value: '$categorias', icon: Icons.category_rounded, color: const Color(0xFF7C3AED)),
            ]);
          }),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 650 ? 2 : 1;
            return GridView.count(crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.6, children: [
              _StatCard(label: 'Valor em estoque (custo)', value: formatarMoeda(valorCusto), icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF0EA5E9)),
              _StatCard(label: 'Valor potencial de venda', value: formatarMoeda(valorVenda), icon: Icons.payments_rounded, color: const Color(0xFF16A34A)),
            ]);
          }),
          const SizedBox(height: 24),
          _GraficoMovimentacoes(movimentos: movimentos),
          const SizedBox(height: 18),
          _ProdutosMaisVendidos(movimentos: movimentos),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Gerencie seus produtos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('Cadastre, pesquise, edite e movimente o estoque.', style: TextStyle(color: Colors.grey.shade600))])),
            const SizedBox(width: 16), FilledButton.icon(onPressed: onOpenProducts, icon: const Icon(Icons.inventory_2_outlined), label: const Text('Ver produtos')),
          ]))),
          const SizedBox(height: 18),
          if (produtos.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Atenção no estoque', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 14),
            ...produtos.where((p) => p.status != StatusEstoque.normal).take(5).map((p) => ListTile(contentPadding: EdgeInsets.zero, leading: _StatusIcon(status: p.status), title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${p.quantidade} unidade(s) • mínimo ${p.estoqueMinimo}'), trailing: _StatusBadge(status: p.status))),
          ]))),
                ]));
              },
            );
          },
        );
      },
    );
  }
}

class _GraficoMovimentacoes extends StatelessWidget {
  final List<Movimentacao> movimentos;
  const _GraficoMovimentacoes({required this.movimentos});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dias = List.generate(14, (i) => hojeSemHora.subtract(Duration(days: 13 - i)));

    final entradas = {for (final d in dias) d: 0};
    final saidas = {for (final d in dias) d: 0};
    for (final m in movimentos) {
      final data = m.data;
      if (data == null) continue;
      final dia = DateTime(data.year, data.month, data.day);
      if (!entradas.containsKey(dia)) continue;
      if (m.tipo == TipoMovimentacao.entrada) {
        entradas[dia] = entradas[dia]! + m.quantidade;
      } else {
        saidas[dia] = saidas[dia]! + m.quantidade;
      }
    }

    final maior = [...entradas.values, ...saidas.values].fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maior == 0 ? 5.0 : maior * 1.25;
    final houveMovimento = movimentos.any((m) => m.data != null && !DateTime(m.data!.year, m.data!.month, m.data!.day).isBefore(dias.first));

    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Movimentações (últimos 14 dias)', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        const _LegendaPonto(cor: Color(0xFF16A34A), texto: 'Entradas'),
        const SizedBox(width: 14),
        const _LegendaPonto(cor: Color(0xFFDC2626), texto: 'Saídas'),
      ]),
      const SizedBox(height: 18),
      SizedBox(
        height: 220,
        child: !houveMovimento
            ? Center(child: Text('Nenhuma movimentação nos últimos 14 dias.', style: TextStyle(color: Colors.grey.shade600)))
            : BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY.round()}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: maxY / 4)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= dias.length || i % 2 != 0) return const SizedBox.shrink();
                    final d = dias[i];
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)));
                  })),
                ),
                barGroups: List.generate(dias.length, (i) {
                  final d = dias[i];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: entradas[d]!.toDouble(), color: const Color(0xFF16A34A), width: 6, borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: saidas[d]!.toDouble(), color: const Color(0xFFDC2626), width: 6, borderRadius: BorderRadius.circular(3)),
                  ]);
                }),
              )),
      ),
    ])));
  }
}

class _LegendaPonto extends StatelessWidget {
  final Color cor;
  final String texto;
  const _LegendaPonto({required this.cor, required this.texto});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
      ]);
}

class _ProdutosMaisVendidos extends StatelessWidget {
  final List<Movimentacao> movimentos;
  const _ProdutosMaisVendidos({required this.movimentos});

  @override
  Widget build(BuildContext context) {
    final vendasPorProduto = <String, int>{};
    for (final m in movimentos) {
      if (m.tipo != TipoMovimentacao.saida) continue;
      vendasPorProduto.update(m.produtoNome, (v) => v + m.quantidade, ifAbsent: () => m.quantidade);
    }
    final ranking = vendasPorProduto.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = ranking.take(5).toList();
    final maiorQuantidade = top5.isEmpty ? 1 : top5.first.value;

    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Produtos mais vendidos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Total de unidades em saídas registradas.', style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 16),
      if (top5.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Nenhuma saída registrada ainda.', style: TextStyle(color: Colors.grey.shade600)))
      else
        ...top5.indexed.map((entry) {
          final (i, item) = entry;
          final proporcao = item.value / maiorQuantidade;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              CircleAvatar(radius: 15, backgroundColor: const Color(0xFF2563EB).withValues(alpha: .10), child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 13))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.key, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    Text('${item.value} un.', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: proporcao, minHeight: 6, backgroundColor: const Color(0xFFE4E8F0), valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)))),
                ]),
              ),
            ]),
          );
        }),
    ])));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))), Text(label, style: TextStyle(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)]))])));
}

class _ErroEstado extends StatelessWidget {
  final String mensagem; const _ErroEstado({required this.mensagem});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cloud_off_rounded, size: 52), const SizedBox(height: 12), const Text('Não foi possível carregar os dados.', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(mensagem, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))])));
}

class _StatusIcon extends StatelessWidget {
  final StatusEstoque status; const _StatusIcon({required this.status});
  @override Widget build(BuildContext context) { final c = status == StatusEstoque.normal ? const Color(0xFF16A34A) : status == StatusEstoque.baixo ? const Color(0xFFF59E0B) : const Color(0xFFDC2626); return CircleAvatar(backgroundColor: c.withValues(alpha: .12), child: Icon(status == StatusEstoque.normal ? Icons.check_rounded : status == StatusEstoque.baixo ? Icons.warning_amber_rounded : Icons.close_rounded, color: c)); }
}

class _StatusBadge extends StatelessWidget {
  final StatusEstoque status; const _StatusBadge({required this.status});
  @override Widget build(BuildContext context) { final c = status == StatusEstoque.normal ? const Color(0xFF16A34A) : status == StatusEstoque.baixo ? const Color(0xFFF59E0B) : const Color(0xFFDC2626); final text = status == StatusEstoque.normal ? 'Normal' : status == StatusEstoque.baixo ? 'Estoque baixo' : 'Sem estoque'; return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: c.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700))); }
}
