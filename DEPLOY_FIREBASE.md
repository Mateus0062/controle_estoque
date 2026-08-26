# Corrigir erro `cloud_firestore/permission-denied`

O aplicativo usa Firebase Authentication + Cloud Firestore. As regras deste projeto ficam em `firestore.rules`.

## 1. Instalar o Firebase CLI

No PowerShell do Windows:

```powershell
npm install -g firebase-tools
```

## 2. Fazer login

```powershell
firebase login
```

## 3. Entrar na pasta do projeto

```powershell
cd caminho\para\controle_estoque_final
```

## 4. Publicar as regras do Firestore

```powershell
firebase deploy --only firestore:rules
```

O arquivo `.firebaserc` deste projeto já aponta para:

`controle-estoque-b1545`

## 5. Executar novamente o Flutter

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

### Importante

Não altere as regras para `allow read, write: if true` apenas para eliminar o erro. Isso deixaria o banco exposto. As regras deste projeto permitem que cada usuário autenticado acesse somente os documentos cujo `usuarioId` seja igual ao seu próprio UID.
