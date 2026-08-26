import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/produto.dart';
import '../servicos/auth_servico.dart';
import '../servicos/firestore_servico.dart';
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
  final _firestore = FirestoreServico();

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
        return StreamBuilder<List<String>>(
          stream: service.listarCategorias(),
          builder: (context, categorySnapshot) {
            final categorias = categorySnapshot.data?.length ?? produtos.map((p) => p.categoria).where((c) => c.isNotEmpty).toSet().length;
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
          const SizedBox(height: 24),
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
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(color: Colors.grey.shade600))])])));
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
