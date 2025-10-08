# Mini Blog - Ruby on Rails

Este repositório é um projeto de estudo em **Ruby on Rails** que implementa um mini blog com funcionalidades básicas de autenticação e CRUD de posts.

## Funcionalidades

- CRUD de posts protegido por autenticação.
- Visualização de posts de outros usuários.
- Autenticação e login de usuários.
- Testes automatizados com **RSpec**.
- Este projeto também inclui o Bruno, uma ferramenta criada para testar a API de forma prática.

## Pré-requisitos

- Ruby
- Rails
- Docker e Docker Compose
- Bundler

## Como rodar o projeto

1. Suba o banco de dados usando Docker Compose:

```bash
docker-compose up -d
```

2. Instale as dependências do projeto:
```bash
bundle install
```

3. Para rodar os testes com RSpec:
```bash
rspec
```

4. Execute o servidor Rails:
```bash
rails s
```
