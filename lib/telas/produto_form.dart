import 'package:flutter/material.dart';

import '../modelos/produto.dart';
import '../servicos/firestore_servico.dart';

class ProdutoForm extends StatefulWidget {
  final Produto? produto;
  const ProdutoForm({super.key, this.produto});

  @override
  State<ProdutoForm> createState() => _ProdutoFormState();
}

class _ProdutoFormState extends State<ProdutoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _codigo = TextEditingController();
  final _descricao = TextEditingController();
  final _quantidade = TextEditingController();
  final _minimo = TextEditingController();
  final _custo = TextEditingController();
  final _venda = TextEditingController();
  final _categoriaNova = TextEditingController();
  final _service = FirestoreServico();

  String? _categoria;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _nome.text = p.nome;
      _codigo.text = p.codigo;
      _descricao.text = p.descricao;
      _quantidade.text = '${p.quantidade}';
      _minimo.text = '${p.estoqueMinimo}';
      _custo.text = p.precoCusto.toStringAsFixed(2).replaceAll('.', ',');
      _venda.text = p.precoVenda.toStringAsFixed(2).replaceAll('.', ',');
      _categoria = p.categoria;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nome, _codigo, _descricao, _quantidade, _minimo, _custo, _venda, _categoriaNova
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _obrigatorio(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;
  }

  String? _inteiro(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório.';
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) return 'Informe uma quantidade válida.';
    return null;
  }

  String? _preco(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null || number < 0) return 'Informe um preço válido.';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null || _categoria!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await _service.salvarProduto(
        id: widget.produto?.id,
        dados: {
          'nome': _nome.text.trim(),
          'codigo': _codigo.text.trim().toUpperCase(),
          'categoria': _categoria,
          'descricao': _descricao.text.trim(),
          'quantidade': int.parse(_quantidade.text.trim()),
          'estoqueMinimo': int.parse(_minimo.text.trim()),
          'precoCusto': double.parse(_custo.text.replaceAll(',', '.')),
          'precoVenda': double.parse(_venda.text.replaceAll(',', '.')),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.produto == null
              ? 'Produto cadastrado com sucesso.'
              : 'Produto atualizado com sucesso.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _novaCategoria() async {
    _categoriaNova.clear();
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: _categoriaNova,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _categoriaNova.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (nome == null || nome.isEmpty) return;
    try {
      await _service.salvarCategoria(nome);
      if (mounted) setState(() => _categoria = nome);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.produto == null ? 'Novo produto' : 'Editar produto')),
      body: StreamBuilder<List<String>>(
        stream: _service.listarCategorias(),
        builder: (context, snapshot) {
          final categorias = <String>{
            ...(snapshot.data ?? const <String>[]),
            if (_categoria != null) _categoria!,
          }.toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dados do produto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Preencha os campos obrigatórios para manter o estoque organizado.', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 700 ? 2 : 1;
                                return GridView.count(
                                  crossAxisCount: columns,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: columns == 2 ? 4.4 : 4.0,
                                  children: [
                                    TextFormField(
                                      controller: _nome,
                                      decoration: const InputDecoration(labelText: 'Nome do produto *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                                      validator: _obrigatorio,
                                    ),
                                    TextFormField(
                                      controller: _codigo,
                                      enabled: widget.produto == null,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: const InputDecoration(labelText: 'Código do produto *', prefixIcon: Icon(Icons.qr_code_2_rounded)),
                                      validator: _obrigatorio,
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: categorias.contains(_categoria) ? _categoria : null,
                                      decoration: const InputDecoration(labelText: 'Categoria *', prefixIcon: Icon(Icons.category_outlined)),
                                      items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (value) => setState(() => _categoria = value),
                                      validator: (value) => value == null ? 'Selecione uma categoria.' : null,
                                    ),
                                    OutlinedButton.icon(onPressed: _novaCategoria, icon: const Icon(Icons.add), label: const Text('Criar nova categoria')),
                                    TextFormField(
                                      controller: _quantidade,
                                      enabled: widget.produto == null,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Quantidade em estoque *',
                                        prefixIcon: const Icon(Icons.numbers_rounded),
                                        helperText: widget.produto == null ? null : 'Altere o estoque por Entrada / Saída.',
                                      ),
                                      validator: _inteiro,
                                    ),
                                    TextFormField(
                                      controller: _minimo,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Estoque mínimo *', prefixIcon: Icon(Icons.low_priority_rounded)),
                                      validator: _inteiro,
                                    ),
                                    TextFormField(
                                      controller: _custo,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Preço de custo *', prefixIcon: Icon(Icons.attach_money_rounded)),
                                      validator: _preco,
                                    ),
                                    TextFormField(
                                      controller: _venda,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Preço de venda *', prefixIcon: Icon(Icons.sell_outlined)),
                                      validator: _preco,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descricao,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(labelText: 'Descrição', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(onPressed: _salvando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: _salvando ? null : _salvar,
                                  icon: _salvando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded),
                                  label: Text(widget.produto == null ? 'Cadastrar produto' : 'Salvar alterações'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
