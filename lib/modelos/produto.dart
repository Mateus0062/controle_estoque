import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusEstoque { normal, baixo, semEstoque }

class Produto {
  final String id;
  final String nome;
  final String codigo;
  final String categoria;
  final String descricao;
  final int quantidade;
  final int estoqueMinimo;
  final double precoCusto;
  final double precoVenda;
  final DateTime? atualizadoEm;

  const Produto({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.categoria,
    required this.descricao,
    required this.quantidade,
    required this.estoqueMinimo,
    required this.precoCusto,
    required this.precoVenda,
    this.atualizadoEm,
  });

  factory Produto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final atualizado = data['atualizadoEm'];
    return Produto(
      id: doc.id,
      nome: (data['nome'] ?? '').toString(),
      codigo: (data['codigo'] ?? '').toString(),
      categoria: (data['categoria'] ?? '').toString(),
      descricao: (data['descricao'] ?? '').toString(),
      quantidade: _toInt(data['quantidade']),
      estoqueMinimo: _toInt(data['estoqueMinimo']),
      precoCusto: _toDouble(data['precoCusto']),
      precoVenda: _toDouble(data['precoVenda']),
      atualizadoEm: atualizado is Timestamp ? atualizado.toDate() : null,
    );
  }

  StatusEstoque get status {
    if (quantidade == 0) return StatusEstoque.semEstoque;
    if (quantidade <= estoqueMinimo) return StatusEstoque.baixo;
    return StatusEstoque.normal;
  }

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
