String formatarMoeda(double valor) {
  final negativo = valor < 0;
  final absoluto = valor.abs();
  final inteiro = absoluto.truncate();
  final centavos = ((absoluto - inteiro) * 100).round().toString().padLeft(2, '0');

  final digitos = inteiro.toString().split('').reversed.toList();
  final agrupado = <String>[];
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && i % 3 == 0) agrupado.add('.');
    agrupado.add(digitos[i]);
  }
  final parteInteira = agrupado.reversed.join();

  return '${negativo ? '-' : ''}R\$ $parteInteira,$centavos';
}
