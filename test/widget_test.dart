import 'package:flutter_test/flutter_test.dart';

import 'package:controle_estoque/modelos/produto.dart';

void main() {
  test('classificação do estoque', () {
    final normal = Produto(id: '1', nome: 'A', codigo: 'A1', categoria: 'Teste', descricao: '', quantidade: 10, estoqueMinimo: 5, precoCusto: 1, precoVenda: 2);
    final baixo = Produto(id: '2', nome: 'B', codigo: 'B1', categoria: 'Teste', descricao: '', quantidade: 5, estoqueMinimo: 5, precoCusto: 1, precoVenda: 2);
    final vazio = Produto(id: '3', nome: 'C', codigo: 'C1', categoria: 'Teste', descricao: '', quantidade: 0, estoqueMinimo: 5, precoCusto: 1, precoVenda: 2);
    expect(normal.status, StatusEstoque.normal);
    expect(baixo.status, StatusEstoque.baixo);
    expect(vazio.status, StatusEstoque.semEstoque);
  });
}
