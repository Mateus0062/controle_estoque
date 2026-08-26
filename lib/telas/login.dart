import 'package:flutter/material.dart';
import '../servicos/auth_servico.dart';
import 'cadastro.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _auth = AuthServico();
  bool _carregando = false;
  bool _ocultar = true;

  @override
  void dispose() { _email.dispose(); _senha.dispose(); super.dispose(); }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try { await _auth.login(_email.text, _senha.text); }
    catch (e) { if (mounted) _erro(e.toString()); }
    finally { if (mounted) setState(() => _carregando = false); }
  }

  void _erro(String mensagem) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Row(children: [
          if (desktop) Expanded(child: Container(
            padding: const EdgeInsets.all(56),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)])),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.inventory_2_rounded, color: Colors.white, size: 64),
              SizedBox(height: 28),
              Text('Controle de Estoque', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
              SizedBox(height: 14),
              Text('Organize produtos, acompanhe o estoque e registre cada movimentação em um só lugar.', style: TextStyle(color: Color(0xFFDDE7FF), fontSize: 18, height: 1.5)),
            ]),
          )),
          Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!desktop) const Center(child: Icon(Icons.inventory_2_rounded, size: 64, color: Color(0xFF2563EB))),
              if (!desktop) const SizedBox(height: 22),
              const Text('Bem-vindo de volta', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Entre com seus dados para acessar o estoque.', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              const SizedBox(height: 28),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido.' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _senha, obscureText: _ocultar, decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _ocultar = !_ocultar), icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.isEmpty) ? 'Informe sua senha.' : null),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: _carregando ? null : _entrar, child: _carregando ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w700))),),
              const SizedBox(height: 14),
              Center(child: TextButton(onPressed: _carregando ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Cadastro())), child: const Text('Ainda não tenho uma conta'))),
            ])),
          ))))
        ]);
      }),
    );
  }
}
