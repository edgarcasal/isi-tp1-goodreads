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

## 3. Decisões de negócio
- Candidatos restringidos a livros em inglês: a maioria das traduções
  publicadas em Portugal vem do inglês.
- Os 10 livros com language_code = "por" já têm edição em português,
  por isso nunca são candidatos.

## 4. Pendentes
- Livro 6549: título começa com espaços.
- publication_date ainda está como texto (converter para data).
- Código "nl" tem 2 letras (os outros têm 3); tratar no idiomas.xml.
- O mesmo livro aparece várias vezes em edições diferentes
  (remover duplicados nos candidatos).