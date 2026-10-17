# Notas do projeto

## 1. Extração

### 1.1 Linhas mal formatadas no books.csv
- **Problema:** o CSV Reader falhava ("The data row has too many data
  elements"). 4 linhas tinham vírgulas dentro do nome dos autores
  (ex.: "Sam Bass Warner, Jr.", "James Wesley, Rawles").
- **Solução:** ler o ficheiro linha a linha (Line Reader) e corrigir
  com regex no String Manipulation:
  `regexReplace($Line$, ", ([^ ])", " $1")`
- **Validação:** a primeira regra (", " → " ") tinha 2 falsos positivos
  (o cabeçalho e o livro 6549, cujo título começa com espaços).
  Testei com Row Filter: a regra final apanha exatamente 4 linhas
  antes da correção e 0 depois.

### 1.2 Ficheiro de staging
- **Problema:** o CSV Writer apagava as vírgulas quando as aspas
  estavam desativadas (o ficheiro ficava com 1 coluna só).
- **Solução:** usar "|" como delimitador no CSV Writer, para as
  vírgulas do texto ficarem intactas.
- **Ordem de execução:** ligação de flow variables entre o CSV Writer
  e o CSV Reader, para o reader só correr depois de o ficheiro existir.
- **Validação:** 11 127 linhas e 12 colunas.

### 1.3 Tipos de dados
- isbn e isbn13 definidos como texto: são identificadores, não
  quantidades (o isbn também pode terminar em "X").
- Coluna "  num_pages" renomeada para "num_pages" (tinha espaços).

### 1.4 API da Open Library
- Pedido por ISBN (search.json), com User-Agent identificado e
  atraso de 1 s entre pedidos.
- JSON Path extrai: numFound, edition_count (1.º resultado),
  idiomas e subjects (todos os resultados, como listas).
- Os códigos de idioma da Open Library diferem dos do Goodreads
  (ex.: chinês "chi" vs "zho").
- Verificação de edição PT: Ungroup da lista de idiomas → filtro
  "por" → GroupBy por livro → left outer join → Rule Engine
  (Sim / Não / Desconhecido).
- Validação com 30 livros: resultados coerentes; caso com 2
  resultados (numFound = 2) tratado corretamente.
- Limitação: coletâneas/edições especiais podem aparecer como
  "Não" mesmo que a obra esteja traduzida.

  ### 1.5 Verificação manual da qualidade da API
- "Desconhecido" (Twelve Sharp, ISBN 0312349486): a Open Library
  não tem este ISBN (numFound = 0). Classificação correta.
- Amostra de 7 livros classificados como "Não", verificados
  manualmente na web:
  - 6 têm edição em português (The Secret Garden, A Little Princess,
    A Walk to Remember, The Rescue, A Bend in the Road, Bleach);
  - 1 sem edição em português encontrada (Moloka'i).
- Conclusão: "Sim" é fiável, mas "Não" só significa "sem registo na
  Open Library" (cobertura fraca de edições portuguesas/brasileiras).
- Decisão: o resultado final é uma pré-seleção de candidatos a
  verificar, não uma lista definitiva.
- Trabalho futuro: confirmar os "Não" com uma segunda fonte.

## 2. Transformação

### 2.1 Normalização do idioma
- **Problema:** o inglês aparecia em 4 códigos diferentes
  (eng, en-US, en-GB, en-CA). 27 códigos no total.
- **Solução:** `regexReplace($language_code$, "^en(g|-[A-Z]+)$", "eng")`
- **Validação:**
  - 27 → 24 códigos (saíram exatamente en-US, en-GB e en-CA);
  - eng: 8 911 + 1 409 + 214 + 7 = 10 541;
  - total de livros continua 11 127;
  - "enm" (inglês médio, 3 livros) ficou de fora, como devia,
    graças ao ^ e $ da regex.

### 2.2 Seleção de candidatos a tradução
- Critérios: idioma = eng, ratings_count ≥ 50 000, average_rating ≥ 4.
- Resultado: 972 livros com ratings_count ≥ 10 000;
  363 livros com ratings_count ≥ 50 000.
- Justificação: um limite de 50 000 avaliações garante que só ficam
  livros com popularidade comprovada (um bom indicador de procura) e
  reduz o número de pedidos à API da Open Library para uma quantidade
  razoável (cerca de 360 pedidos, em vez de quase 1000).

### 2.3 Duplicados
- Duas edições da mesma obra têm o mesmo identificador na Open
  Library (ol_work_key). Duplicate Row Filter por ol_work_key,
  mantendo a edição com mais avaliações.
- 3 duplicados removidos: 363 → 360 livros.
- Candidatos "Não" (pré-seleção a verificar): 255

### 2.4 Géneros (regex + generos.xml)
- Regras de géneros num ficheiro XML externo (8 géneros, padrões regex).
- Falsos positivos encontrados e corrigidos:
  - "science" apanhava "science fiction" → `science(?! fiction)`
    (negative lookahead);
  - "war" apanhava "warlocks" e "award" → `\bwar\b`
    (fronteira de palavra).
- Correção feita só no XML, sem alterar o workflow.
- Resultado (255 candidatos): Fantasia 52, Histórico 39, Juvenil 37,
  Policial e thriller 37, Outro 25, Biografia 23, Romance 17,
  Não-ficção 13, Ficção científica 12. Total confirmado: 255.
- Género principal = o género com mais subjects correspondentes.
  Limitação: em caso de empate, fica um dos géneros empatados.
- 25 livros (~10%) sem género reconhecido → "Outro".

### 2.5 Ranking
- Pontuação ponderada (fórmula do IMDb):
  (v/(v+m))·R + (m/(v+m))·C, com m = 50 000 e C = 3,943.
- C calculado no próprio workflow (média dos livros com
  ratings_count > 0) e passado como flow variable.
- Posição dentro de cada género (Rank, modo ordinal), com
  edition_count como critério de desempate.
- Resultado: 255 candidatos ordenados por género.

## 3. Decisões de negócio
- Candidatos restringidos a livros em inglês: a maioria das traduções
  publicadas em Portugal vem do inglês.
- Os 10 livros com language_code = "por" já têm edição em português,
  por isso nunca são candidatos.

## 4. Pendentes
- Livro 6549: título começa com espaços.
- publication_date ainda está como texto (converter para data).
- Código "nl" tem 2 letras (os outros têm 3); tratar no idiomas.xml.
- Códigos de idioma da Open Library diferem dos do Goodreads
  (ex.: "chi" vs "zho"); mapear ambos no idiomas.xml.
- O mesmo livro aparece várias vezes em edições diferentes
  (remover duplicados nos candidatos).
- Subjects confusos (várias línguas, etiquetas técnicas como
  "nyt:..." e "Reading Level"); converter em géneros com regex
  e generos.xml.
- Remover colunas técnicas antes de carregar na BD: body, url,
  Status, Content type, bookID (Right), Count*(ol_languages).