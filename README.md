# The Game Award (Flutter + SQLite)

Aplicativo para cadastro de usuários, jogos, categorias e votação nos indicados ao estilo The Game Awards.

## Funcionalidades

- Cadastro/Login/Convidado; papéis: administrador (role=0) e usuário comum (role=1).
- Dashboard:
	- Admin: atalhos para CRUD de Jogos, CRUD de Categorias e Associação Jogos↔Categorias.
	- Ambos: filtros por Categoria (incluindo inativas), Gênero e Posição (Top 3) + busca.
- Usuário comum logado pode votar, trocar ou retirar voto por categoria ativa; visitante só visualiza.
- Banco local SQLite com `sqflite_common_ffi` (desktop) e `sqlite3_flutter_libs` para empacotar a lib nativa.

## Estrutura (pasta `lib/`)

- `main.dart`: bootstrap do app, inicializa SQLite (FFI), providers e rotas.
- `src/db/db.dart`: schema do SQLite e seed (admin padrão e alguns gêneros).
- `src/providers/auth_provider.dart`: estado de autenticação.
- Telas:
	- `src/screens/auth/landing_screen.dart`, `login_screen.dart`, `register_screen.dart`.
	- `src/screens/dashboard_screen.dart` (filtros, atalhos admin, categorias ativas).
	- Admin: `admin/games_crud_screen.dart`, `admin/categories_crud_screen.dart`, `admin/category_games_screen.dart`.
	- Usuário: `user/category_list_screen.dart`, `user/category_details_screen.dart` (votação).
	- Busca: `search_screen.dart`.

## Schema SQL (SQLite)

Tabelas: `user`, `genre`, `game`, `game_genre`, `category`, `category_game`, `user_vote`.
Foreign keys habilitadas com `PRAGMA foreign_keys = ON`.

Admin seed: `email: admin@award.app`, `senha: admin`.

## Executar (Linux Desktop)

Requisitos: Flutter 3.35+, Dart 3.9+, toolchain Linux.

```bash
flutter pub get
flutter run -d linux
```

Obs.: O banco `award.db` é criado no diretório do projeto e está no `.gitignore`.

## Publicação no GitHub

```bash
git init -b main
git add .
git commit -m "Initial commit: The Game Award app"
git remote add origin <URL_DO_REPO>
git push -u origin main
```

Ou com GitHub CLI (`gh`):

```bash
gh repo create the_game_award_app --private --source=. --remote=origin --push
```

## Prints/Vídeo

- Faça login admin e cadastre alguns jogos/categorias.
- Associe jogos às categorias e, com usuário comum, vote nas categorias ativas.
- Capture tela da Dashboard, CRUDs, lista de categorias e tela de votação.
