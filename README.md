# Controle de Despesas – Flutter + Firebase

Aplicativo mobile desenvolvido em Flutter como projeto de estudo, com o objetivo de praticar gerenciamento de estado, integração com Firebase, autenticação, persistência de dados em nuvem e testes de widgets.

O app permite que cada usuário registre, categorize e acompanhe suas despesas pessoais de forma simples e organizada.

## Funcionalidades

- Autenticação de usuários com Firebase Authentication
- Cadastro, edição e remoção de despesas
- Gerenciamento de categorias e tags
- Organização das despesas por data
- Persistência dos dados no Firebase Realtime Database
- Dados isolados por usuário autenticado
- Interface com tema escuro
- Testes de widget utilizando Mockito

## Arquitetura do Projeto

O projeto segue uma arquitetura simples, separando bem responsabilidades:

- **Models**: representam as entidades do sistema (despesa, categoria e tag).
- **Provider**: gerencia o estado da aplicação e a comunicação com o Firebase.
- **Screens**: telas da aplicação.
- **Widgets**: componentes reutilizáveis de UI.
- **Services**: regras de acesso ao Firebase.

## Modelos de Dados

### Expense

Representa uma despesa registrada pelo usuário, contendo:
- valor
- categoria
- tag
- observação
- data

### ExpenseCategory

Define as categorias de despesas, com suporte a categorias padrão.

### Tag

Permite classificar despesas com etiquetas personalizadas.

Todos os modelos possuem métodos `toMap` e `fromMap` para integração direta com o Firebase.

## Firebase

O projeto utiliza:

### Firebase Authentication
Login e controle de usuários.

### Firebase Realtime Database
Armazenamento das despesas, categorias e tags.

Cada usuário possui seus próprios dados, organizados no banco a partir do `uid`.

## Testes

O projeto conta com testes de widget utilizando Mockito, permitindo:

- Mock do ExpenseProvider
- Execução de testes sem necessidade de inicializar o Firebase real
- Validação do carregamento da tela inicial

Arquivos principais de teste:
- `mock_expense_provider.dart`
- `widget_test.dart`

## Galeria de Imagens

Telas do sistema em funcionamento:

## - Telas de Login e Cadastro:
<img width="401" height="866" alt="telaLogin" src="https://github.com/user-attachments/assets/2b9496a4-6fb0-4e28-ba10-20ac15595b04" />
<img width="400" height="866" alt="telaCadastro" src="https://github.com/user-attachments/assets/8c53a7ae-5a4d-49e5-8135-517ed1b01efb" />

## - Telas de Visão Filtradas por Data e por Categoria:
<img width="402" height="868" alt="telaFiltradaData" src="https://github.com/user-attachments/assets/7faf7042-e4e4-48d0-a178-3cb2e2269cf9" />
<img width="402" height="867" alt="telaFiltradaCategoria" src="https://github.com/user-attachments/assets/22aab0f9-b784-4893-a66f-620eb5ae89ea" />

## - Tela de Adição de Despesas e Menu:
<img width="400" height="868" alt="telaAdicaoDespesa" src="https://github.com/user-attachments/assets/0948052d-acc9-441d-9b3d-bd26fdb82268" />
<img width="402" height="869" alt="telaMenu" src="https://github.com/user-attachments/assets/d0f733e7-086e-497b-af94-ccf0874aedb4" />

## - Telas de Gerenciamento de Tags e de Categorias:
<img width="402" height="869" alt="telaGerenciaTags" src="https://github.com/user-attachments/assets/55f75aae-92c6-4e62-8195-5074e3613d67" />
<img width="402" height="869" alt="telaGerenciaCategorias" src="https://github.com/user-attachments/assets/c5b9b4fd-8e7c-4ed4-b4fd-ef7e69ed0872" />

## - Adição de novas Tags e Categorias:
<img width="400" height="871" alt="telaAdicionandoTag" src="https://github.com/user-attachments/assets/1a2bd6b9-efa4-4f7d-88e4-209c22643348" />
<img width="402" height="869" alt="telaAdicionandoCategoria" src="https://github.com/user-attachments/assets/b3b3212c-10b6-41c1-af5b-a84c16aedbf0" />

## Objetivo do Projeto

Projeto desenvolvido exclusivamente para fins de estudo, com foco em:

- Flutter
- Gerenciamento de estado
- Integração com Firebase
- Boas práticas de organização de código
- Testes automatizados
