import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/movimentacao.dart';
import '../modelos/produto.dart';

class FirestoreServico {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? (throw StateError('Usuário não está logado.'));
  String get _email => _auth.currentUser?.email ?? 'Usuário';

  CollectionReference<Map<String, dynamic>> get _produtos => _db.collection('produtos');
  CollectionReference<Map<String, dynamic>> get _movimentacoes => _db.collection('movimentacoes');
  CollectionReference<Map<String, dynamic>> get _categorias => _db.collection('categorias');

  Stream<List<Produto>> listarProdutos() => _produtos
      .where('usuarioId', isEqualTo: _uid)
      .snapshots()
      .map((snapshot) {
        final produtos = snapshot.docs.map(Produto.fromDoc).toList();
        produtos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return produtos;
      });

  Future<String> salvarProduto({String? id, required Map<String, dynamic> dados}) async {
    final codigo = (dados['codigo'] ?? '').toString().trim().toUpperCase();
    if (codigo.isEmpty) throw StateError('O código do produto é obrigatório.');

    final repetido = await _produtos.where('usuarioId', isEqualTo: _uid).get();
    if (repetido.docs.any((doc) => doc.id != id && (doc.data()['codigo'] ?? '').toString().toUpperCase() == codigo)) {
      throw StateError('Já existe um produto com este código.');
    }

    final payload = {
      ...dados,
      'codigo': codigo,
      'usuarioId': _uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      payload['criadoEm'] = FieldValue.serverTimestamp();
      final ref = await _produtos.add(payload);
      return ref.id;
    }

    await _produtos.doc(id).update(payload);
    return id;
  }

  Future<void> excluirProduto(String id) async {
    final doc = await _produtos.doc(id).get();
    if (!doc.exists || doc.data()?['usuarioId'] != _uid) {
      throw StateError('Produto não encontrado.');
    }
    await _produtos.doc(id).delete();
  }

  Future<void> movimentarProduto({
    required String produtoId,
    required TipoMovimentacao tipo,
    required int quantidade,
  }) async {
    if (quantidade <= 0) throw StateError('A quantidade deve ser maior que zero.');

    final produtoRef = _produtos.doc(produtoId);
    final movimentoRef = _movimentacoes.doc();

    await _db.runTransaction((transaction) async {
      final produtoDoc = await transaction.get(produtoRef);
      if (!produtoDoc.exists) throw StateError('Produto não encontrado.');

      final data = produtoDoc.data() ?? {};
      if (data['usuarioId'] != _uid) throw StateError('Operação não autorizada.');
      final atual = (data['quantidade'] as num?)?.toInt() ?? 0;
      final novaQuantidade = tipo == TipoMovimentacao.entrada ? atual + quantidade : atual - quantidade;

      if (novaQuantidade < 0) {
        throw StateError('Operação não permitida. Estoque disponível: $atual unidade(s).');
      }

      transaction.update(produtoRef, {'quantidade': novaQuantidade, 'atualizadoEm': FieldValue.serverTimestamp()});
      transaction.set(movimentoRef, {
        'produtoId': produtoId,
        'produtoNome': (data['nome'] ?? '').toString(),
        'tipo': tipo == TipoMovimentacao.entrada ? 'entrada' : 'saida',
        'quantidade': quantidade,
        'data': FieldValue.serverTimestamp(),
        'usuarioId': _uid,
        'usuarioEmail': _email,
      });
    });
  }

  Stream<List<Movimentacao>> listarMovimentacoes() => _movimentacoes
      .where('usuarioId', isEqualTo: _uid)
      .snapshots()
      .map((snapshot) {
        final lista = snapshot.docs.map(Movimentacao.fromDoc).toList();
        lista.sort((a, b) => (b.data ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.data ?? DateTime.fromMillisecondsSinceEpoch(0)));
        return lista;
      });

  Stream<List<String>> listarCategorias() => _categorias
      .where('usuarioId', isEqualTo: _uid)
      .snapshots()
      .map((snapshot) {
        final lista = snapshot.docs.map((doc) => (doc.data()['nome'] ?? '').toString()).where((e) => e.isNotEmpty).toList();
        lista.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return lista;
      });

  Future<void> salvarCategoria(String nome) async {
    final categoria = nome.trim();
    if (categoria.isEmpty) throw StateError('Informe o nome da categoria.');
    final existente = await _categorias.where('usuarioId', isEqualTo: _uid).get();
    if (existente.docs.any((doc) => (doc.data()['nome'] ?? '').toString().toLowerCase() == categoria.toLowerCase())) {
      throw StateError('Esta categoria já existe.');
    }
    await _categorias.add({'nome': categoria, 'usuarioId': _uid, 'criadoEm': FieldValue.serverTimestamp()});
  }

  Future<void> excluirCategoria(String nome) async {
    final snapshot = await _categorias.where('usuarioId', isEqualTo: _uid).get();
    final selecionadas = snapshot.docs.where((doc) => (doc.data()['nome'] ?? '').toString() == nome);
    for (final doc in selecionadas) {
      await doc.reference.delete();
    }
  }
}
