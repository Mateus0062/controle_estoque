import 'package:flutter/material.dart';
import '../modelos/produto.dart';
import 'movimentacao.dart';

/// Compatibilidade com o nome usado na primeira versão do projeto.
/// O aplicativo agora trabalha com movimentações reais de estoque.
class NovoLancamento extends StatelessWidget {
  final Produto produto;
  const NovoLancamento({super.key, required this.produto});
  @override
  Widget build(BuildContext context) => MovimentacaoForm(produto: produto);
}
