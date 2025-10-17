# Scripts SQL do Banco de Dados

Esta pasta contém os scripts SQL que são executados automaticamente durante a inicialização do container PostgreSQL.

## Estrutura

- `01-create-schema.sql`: Cria o schema `app_data` separado do schema `public` usado pelo n8n
- `02-create-tables.sql`: Cria as tabelas da aplicação (atividades e cards_trello)

## Schema app_data

O schema `app_data` foi criado para separar os dados da sua aplicação dos dados internos do n8n, que usa o schema `public`.

### Tabelas

#### atividades
Armazena informações sobre atividades/entregas do projeto:
- Campos principais: id_entrega, identificador, descrição, cliente, vendedor, PMO, etc.
- Controle de datas: início, previsão e conclusão
- Controle de horas: previstas, realizadas e saldo
- Soft delete: `deleted_at` e `is_active`
- Hash para detectar mudanças: `hash_dados`

#### cards_trello
Armazena a sincronização com cards do Trello:
- Vinculado a atividades via `id_entrega`
- Controla última sincronização
- Hash para detectar mudanças no Trello

### Recursos

- **Triggers automáticos**: Os campos `updated_at` são atualizados automaticamente
- **Índices**: Criados para otimizar queries comuns
- **Soft Delete**: Ambas as tabelas suportam exclusão lógica

## Acesso via n8n

Para acessar essas tabelas nos seus workflows do n8n, use:

```sql
-- Opção 1: Especificar o schema completo
SELECT * FROM app_data.atividades;

-- Opção 2: O search_path já inclui app_data, então pode usar direto
SELECT * FROM atividades;
```

## Adicionar novas tabelas

Para adicionar novas tabelas:
1. Crie um novo arquivo SQL (ex: `03-create-nova-tabela.sql`)
2. Use `SET search_path TO app_data, public;` no início
3. Os scripts são executados em ordem alfabética/numérica
4. Reinicie o container do postgres ou delete o volume `db_storage`

## Importante

⚠️ Os scripts em `/docker-entrypoint-initdb.d/` só são executados quando o banco de dados é criado pela primeira vez.

Se você já tem o banco criado e quer aplicar novos scripts:
1. Pare os containers: `docker-compose down`
2. Remova o volume do banco: `docker volume rm docker-n8n_db_storage`
3. Suba novamente: `docker-compose up -d`

Ou execute os scripts manualmente no banco existente.
