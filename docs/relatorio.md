# Relatório do Projeto: The Game Award App

## Objetivo
- Aplicativo inspirado no The Game Awards com fluxos de administrador e usuário comum.
- Funcionalidades: CRUD de jogos/categorias, associação de jogos↔categorias e jogos↔gêneros, votação por categoria, filtros e busca.
- Persistência local via SQLite (desktop) com `sqflite_common_ffi` e integridade referencial.

## Tecnologias
- Flutter (Material 3), Provider para estado (autenticação), `sqflite_common_ffi` + `sqlite3_flutter_libs`.
- Utilitários: `intl`, `path`.

## Estrutura
- `lib/main.dart`: bootstrap, inicialização do SQLite FFI, `MultiProvider`, rotas, tema.
- `lib/src/db/db.dart`: schema completo + rotina de seed idempotente que replica o conteúdo do `script_award.sql` (apenas novo seed ativo).
- `lib/src/providers/auth_provider.dart`: login/register/guest/logout; `role`: 0=admin, 1=usuário.
- `lib/src/screens/`
  - `auth/landing_screen.dart`: entrada (login/registro/guest).
  - `auth/login_screen.dart`, `auth/register_screen.dart`.
  - `dashboard_screen.dart`: filtros (categoria/gênero/posição), atalhos admin, lista de categorias ativas. Tap de categoria → tela de votação.
  - Admin: `games_crud_screen.dart`, `categories_crud_screen.dart`, `category_games_screen.dart`, `game_genres_screen.dart`.
  - Usuário: `category_details_screen.dart` (votação), `category_list_screen.dart` (legado), `search_screen.dart` (resultados por associação jogo↔categoria).

## Banco de Dados (SQLite)
- Tabelas:
  - `user(id, name, email UNIQUE, password, role)`.
  - `genre(id, name UNIQUE)`.
  - `game(id, user_id FK, name UNIQUE, description, release_date)`.
  - `game_genre(game_id, genre_id)` PK composto; FKs ON DELETE CASCADE.
  - `category(id, user_id FK, title, description, date)`.
  - `category_game(id, category_id FK, game_id FK, UNIQUE(category_id, game_id))`.
  - `user_vote(id, user_id FK, category_id FK, vote_game_id FK→category_game.id, UNIQUE(user_id, category_id))`.
- Integridade: `PRAGMA foreign_keys=ON`.
- Modelagem do voto: referencia `category_game.id` para garantir voto apenas em jogo associado à categoria.

## Seed (somente novo)
- Usuários Teste 1..5 com papéis conforme o script.
- Gêneros PT: Aventura, Ação, RPG, Indie, Plataforma, Metroidvania, Rogue Lite, Survival Horror, Mundo Aberto.
- Jogos: Clair Obscur: Expedition 33, Hades 2, Hollow Knight: Silksong, Death Stranding 2, Donkey Kong Bananza, Kingdom Come: Deliverance II.
- Associações `game_genre` conforme o script.
- Categorias: Game of the Year, Best Narrative, Best RPG, Best Family, Best Independent Game, Best Fighting.
- Associações `category_game` e votos convertidos para nosso esquema.
- Idempotente: não duplica conteúdo.

## Fluxos
- Admin:
  - CRUD jogos/categorias.
  - Associar jogos↔categorias; associar gêneros↔jogos.
- Usuário comum:
  - Dashboard → categoria ativa → votação.
  - Busca: resultados por associação (um mesmo jogo pode aparecer em várias categorias). Tap (usuário comum) → tela de votação da categoria.

## Filtros e Busca
- Filtros: Categoria (limpar para “Todas”), Gênero (limpar para “Todos”), Posição (Top N por categoria).
- Busca: baseada em `category_game` + `game` + `category`.
  - Filtro de gênero via `EXISTS` em `game_genre`.
  - Posição: calcula o N‑ésimo por votos dentro de cada categoria (respeitando filtros). 
  - Exibe “Categoria: <título> · Votos: <n>”.

## Execução
```bash
cd "/home/operador/Documentos/Facul/Lab Disp Móveis/the_game_award_app"
flutter run -d linux
```
- Resetar BD:
```bash
rm -f "/home/operador/Documentos/Facul/Lab Disp Móveis/the_game_award_app/award.db"
flutter run -d linux
```

## Inspeção do BD
- DB Browser (via Snap):
```bash
sudo snap install sqlitebrowser
sqlitebrowser "/home/operador/Documentos/Facul/Lab Disp Móveis/the_game_award_app/award.db"
```

## Capturas (adicionar posteriormente)
- `docs/img/landing.png`: Landing.
- `docs/img/dashboard.png`: Dashboard com filtros.
- `docs/img/admin_games.png`: CRUD Jogos.
- `docs/img/admin_categories.png`: CRUD Categorias.
- `docs/img/assoc_category_game.png`: Associação Jogos↔Categorias.
- `docs/img/assoc_game_genre.png`: Associação Gêneros↔Jogos.
- `docs/img/voting.png`: Votação por categoria.
- `docs/img/search.png`: Busca com filtros.

## Melhorias Futuras
- Mover `award.db` para pasta de dados do app (via `path_provider`).
- Tela de relatório de votos (join completo user/category/game).
- Paginação em listas e busca.

## Repositório
- GitHub: `https://github.com/BrunoMarchiori/the_game_awards_app` (branch `main`).