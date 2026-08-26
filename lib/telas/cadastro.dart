import 'package:flutter/material.dart';
import '../servicos/auth_servico.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});
  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _auth = AuthServico();
  bool _carregando = false;
  bool _ocultar = true;

  @override
  void dispose() { _email.dispose(); _senha.dispose(); _confirmacao.dispose(); super.dispose(); }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _auth.cadastrar(_email.text, _senha.text);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada com sucesso!'), behavior: SnackBarBehavior.floating)); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating)); }
    finally { if (mounted) setState(() => _carregando = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Criar conta')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.person_add_alt_1_rounded, size: 48, color: Color(0xFF2563EB)), const SizedBox(height: 16),
      const Text('Nova conta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      Text('Cadastre seu acesso ao sistema.', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 26),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido.' : null), const SizedBox(height: 14),
      TextFormField(controller: _senha, obscureText: _ocultar, decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _ocultar = !_ocultar), icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.length < 6) ? 'Use pelo menos 6 caracteres.' : null), const SizedBox(height: 14),
      TextFormField(controller: _confirmacao, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar senha', prefixIcon: Icon(Icons.verified_user_outlined)), validator: (v) => v != _senha.text ? 'As senhas não coincidem.' : null), const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: _carregando ? null : _cadastrar, child: _carregando ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Criar conta'))),
    ]))))))));
  }
}


