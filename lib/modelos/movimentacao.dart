import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoMovimentacao { entrada, saida }

class Movimentacao {
  final String id;
  final String produtoId;
  final String produtoNome;
  final TipoMovimentacao tipo;
  final int quantidade;
  final DateTime? data;
  final String usuarioEmail;

  const Movimentacao({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.tipo,
    required this.quantidade,
    required this.data,
    required this.usuarioEmail,
  });

  factory Movimentacao.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['data'];
    return Movimentacao(
      id: doc.id,
      produtoId: (data['produtoId'] ?? '').toString(),
      produtoNome: (data['produtoNome'] ?? '').toString(),
      tipo: data['tipo'] == 'saida' ? TipoMovimentacao.saida : TipoMovimentacao.entrada,
      quantidade: data['quantidade'] is num ? (data['quantidade'] as num).toInt() : 0,
      data: timestamp is Timestamp ? timestamp.toDate() : null,
      usuarioEmail: (data['usuarioEmail'] ?? '').toString(),
    );
  }
}
