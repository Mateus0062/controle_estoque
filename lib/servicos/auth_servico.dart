import 'package:firebase_auth/firebase_auth.dart';

class AuthServico {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get estado => _auth.authStateChanges();

  User? usuarioAtual() => _auth.currentUser;

  Future<UserCredential> cadastrar(String email, String senha) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return credencial;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagem(e.code));
    }
  }

  Future<UserCredential> login(String email, String senha) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagem(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  String _mensagem(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Não foi possível conectar ao servidor.';
      default:
        return 'Não foi possível concluir a autenticação. Tente novamente.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
