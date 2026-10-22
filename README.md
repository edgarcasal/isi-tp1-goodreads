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
- Parte 2 — Pentaho Kettle: https://youtu.be/dqoOvzl8H5E

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
| `data/output/logs/log_execucoes.csv` | Histórico de execuções do processo (KNIME) |
| `data/output/livros_candidatos.xlsx` | Resultado da versão Kettle em Excel |
| `data/output/logs/t1.log`, `t2.log` | Logs das transformações do Kettle |
| `src/sql/schema.sql` | Criação das tabelas e da vista (schema `public`, KNIME) |
| `src/sql/schema_kettle.sql` | Criação das tabelas do Kettle (schema `kettle`) |
| `src/sql/goodread_etl_dump.sql` | Cópia da base de dados com os dados carregados |

A pasta `data/staging/` é gerada pelo workflow durante a execução e não está incluída.

## Ferramentas necessárias

- PostgreSQL 18 (e pgAdmin)
- KNIME Analytics Platform 5.x
- Pentaho Data Integration (Kettle) 10.2, com o driver JDBC do PostgreSQL recente (`postgresql-42.7.x.jar`) em `data-integration/lib/`
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

A versão do Kettle é uma versão reduzida do processo (sem classificação por género nem ranking).
Os ficheiros estão em `dataintegration/kettle/`:

| Ficheiro | O que faz |
|---|---|
| `t1_limpeza.ktr` | Lê o `books.csv`, corrige as linhas com vírgulas nos autores, define os tipos, normaliza o idioma, filtra os candidatos e grava em `kettle.candidatos` |
| `t2_api.ktr` | Consulta a Open Library para cada candidato, classifica a edição em português, remove duplicados e grava em `kettle.livros_final` e no Excel |
| `job_etl.kjb` | Executa a `t1` e a `t2` por ordem, envia email de sucesso ou de alerta e regista logs |

**Preparação**

1. Confirmar que o schema `kettle` existe na base `goodreads_etl` (secção 1, passo 3).
2. Confirmar que a pasta `data/output/logs/` existe (o Kettle não a cria sozinho).
3. Definir as variáveis no ficheiro `kettle.properties`
   (Windows: `C:\Users\<utilizador>\.kettle\kettle.properties`; Linux/macOS: `~/.kettle/kettle.properties`).
   Este ficheiro fica fora do repositório, por isso as credenciais não são versionadas:

        PG_USER=<utilizador do PostgreSQL>
        PG_PASS=<password do PostgreSQL>
        DATA_DIR=<caminho completo da pasta data do projeto, com barras normais>
        SMTP_USER=<email que envia as notificações>
        SMTP_PASS=<password desse email>
        SMTP_TO=<email que recebe as notificações>

   Exemplo: `DATA_DIR=C:/isi-tp1-goodreads/data`. Depois de editar o ficheiro, **reiniciar o Spoon**,
   porque só lê as variáveis ao arrancar.

**Execução**

1. Abrir o Spoon (`spoon.bat` em Windows, `spoon.sh` em Linux/macOS).
2. **File → Open** → `dataintegration/kettle/job_etl.kjb`.
3. Em **View → Database connections**, fazer **Test** à ligação `goodreads_pg` (deve dar "Connection successful").
4. Executar o job com o botão ▶. Demora cerca de 7 minutos, devido aos 363 pedidos à API
   com intervalo de 1 segundo.

Para executar só uma transformação, abrir `t1_limpeza.ktr` e depois `t2_api.ktr` (por esta ordem,
porque a `t2` lê a tabela criada pela `t1`) e carregar em ▶.

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
- Versão Kettle: tabelas `kettle.candidatos` (363) e `kettle.livros_final` (cerca de 361, com a coluna `edicao_pt`), e o ficheiro `data/output/livros_candidatos.xlsx`. Os valores da API podem variar ligeiramente, porque os dados da Open Library mudam.
- Email de resumo, com o ranking em anexo, no fim de cada execução.
- Dashboard com os candidatos por género, o melhor candidato de cada género e o histórico de execuções.
