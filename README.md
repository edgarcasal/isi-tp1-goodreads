# Que livros traduzir? — Processo ETL com KNIME e Pentaho Kettle

Trabalho Prático I de **Integração de Sistemas de Informação**
Licenciatura em Engenharia de Sistemas Informáticos — EST | UPCA, 2026/27

## Autores

| Nome | Número | Plataforma |
|---|---|---|
| Edgar Casal | a31026 | KNIME Analytics Platform |
| João Simão Machado | a31510 | Pentaho Data Integration (Kettle) |

## Descrição

Processo ETL que ajuda uma editora portuguesa (cenário imaginário) a identificar
livros populares e bem avaliados que ainda não têm edição em português.

O processo:
- lê e corrige o dataset Goodreads-books (CSV, 11 127 livros);
- consulta a API da Open Library (JSON) para verificar se cada livro tem edição em português;
- classifica os candidatos por género com regras em XML (expressões regulares);
- calcula um ranking por género com uma média ponderada;
- carrega os resultados em PostgreSQL, exporta CSV e JSON, regista um log de execuções,
  envia um email de resumo e apresenta os resultados num dashboard em Node-RED.

## Demonstração (vídeos)

- Parte 1 — KNIME, PostgreSQL e Node-RED: https://youtu.be/X_69v7VZAiQ
- Parte 2 — Pentaho Kettle: 

## Estrutura dos ficheiros

| Pasta / ficheiro | Conteúdo |
|---|---|
| `doc/31026_31510_doc.pdf` | Relatório final |
| `dataintegration/knime/goodreads_etl.knwf` | Workflow KNIME (processo ETL completo) |
| `dataintegration/kettle/` | Transformações (.ktr) e jobs (.kjb) do Kettle |
| `dataintegration/nodered/flows.json` | Fluxo Node-RED do dashboard |
| `data/input/books.csv` | Dataset Goodreads-books (Kaggle) |
| `data/input/generos.xml` | Regras de classificação por género (regex) |
| `data/output/ranking_candidatos.csv` | Ranking de candidatos por género (CSV) |
| `data/output/ranking_candidatos_0.json` | Ranking de candidatos por género (JSON) |
| `data/output/logs/log_execucoes.csv` | Histórico de execuções do processo |
| `src/sql/schema.sql` | Criação das tabelas e da vista (schema `public`, KNIME) |
| `src/sql/schema_kettle.sql` | Criação das tabelas do Kettle (schema `kettle`) |
| `src/sql/goodread_etl_dump.sql` | Cópia da base de dados com os dados carregados |

A pasta `data/staging/` é gerada pelo workflow durante a execução e não está incluída.

## Ferramentas necessárias

- PostgreSQL 18 (e pgAdmin)
- KNIME Analytics Platform 5.x
- Pentaho Data Integration (Kettle)
- Node.js e Node-RED, com os módulos `node-red-contrib-postgresql` e `@flowfuse/node-red-dashboard`
- Uma conta de email com acesso SMTP (foi usado o Office 365)

## Como executar

### 1. Base de dados

1. No pgAdmin, criar a base de dados `goodreads_etl`.
2. Executar `src/sql/schema.sql` no Query Tool, para criar as tabelas vazias,
   **ou** executar `src/sql/goodread_etl_dump.sql`, para restaurar a base de dados já com os dados.
3. Para a parte do Kettle, executar também `src/sql/schema_kettle.sql`.

### 2. KNIME

1. Importar o workflow: **File → Import KNIME Workflow** → `dataintegration/knime/goodreads_etl.knwf`.
2. Ajustar os caminhos dos ficheiros (leitura do CSV e do XML, staging e ficheiros de saída)
   para a pasta onde o projeto foi guardado.
3. No `PostgreSQL Connector`, indicar o utilizador e a password da base de dados.
4. No `Credentials Configuration`, indicar as credenciais do email
   (a password não é guardada no workflow).
5. Executar todo o workflow (**Shift + F7**). A consulta à API demora cerca de 6 minutos,
   devido ao intervalo de 1 segundo entre pedidos.

### 3. Pentaho Kettle

a completar...

### 4. Dashboard (Node-RED)

    npm install -g --unsafe-perm node-red
    node-red

1. Abrir http://127.0.0.1:1880.
2. Em **Manage palette**, instalar `node-red-contrib-postgresql` e `@flowfuse/node-red-dashboard`.
3. **Import** → `dataintegration/nodered/flows.json`.
4. Na ligação à base de dados, indicar o utilizador e a password (SSL desativado) e fazer **Deploy**.
5. Abrir o dashboard em http://127.0.0.1:1880/dashboard.

## Resultados

- Tabelas `livros` (11 127), `candidatos` (255) e `log_execucoes`, e vista `v_ranking`, no PostgreSQL.
- Ranking por género em CSV e JSON (`data/output/`).
- Email de resumo, com o ranking em anexo, no fim de cada execução.
- Dashboard com os candidatos por género, o melhor candidato de cada género e o histórico de execuções.