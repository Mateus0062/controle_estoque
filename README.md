# Controle de Estoque

Aplicativo Flutter/Dart para controle de produtos, estoque e movimentações, com Firebase Authentication e Cloud Firestore.

## Funcionalidades

- Cadastro, login e logout com Firebase Authentication.
- Dashboard com total de produtos, estoque baixo, produtos sem estoque e categorias.
- Cadastro e edição de produtos.
- Listagem e pesquisa por nome, código e categoria.
- Classificação automática: Normal, Estoque baixo e Sem estoque.
- Entrada e saída de produtos com atualização persistida no Firestore.
- Bloqueio de saída maior que o estoque disponível.
- Histórico de entradas e saídas com data e usuário responsável.
- Exclusão de produtos com confirmação.
- Cadastro e exclusão de categorias.
- Interface responsiva para dispositivos móveis e telas maiores.

## Estrutura do Firestore

- `produtos`
- `movimentacoes`
- `categorias`

Todos os registros são associados ao `uid` do usuário autenticado.

## Execução

```bash
flutter pub get
flutter run
```

O projeto já contém a configuração do Firebase em `lib/firebase_options.dart`. As regras do Firestore devem permitir acesso aos documentos do usuário autenticado e ser configuradas de acordo com o ambiente de produção.
