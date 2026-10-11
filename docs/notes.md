# Notas do projeto

## Extração do books.csv
- Problema: 4 linhas falhavam na leitura ("too many data elements")
  porque os nomes dos autores tinham vírgulas (ex.: "Sam Bass Warner, Jr.").
- Primeira regra (", " → " ") tinha 2 falsos positivos: o cabeçalho
  e o livro 6549 (título começa com espaços).
- Regra final (regex): ", ([^ ])" → " $1". Validada com Row Filter:
  4 linhas antes, 0 depois.
- O CSV Writer apagava as vírgulas com aspas desativadas; resolvido
  usando "|" como delimitador do ficheiro de staging.
- Resultado: 11 127 linhas e 12 colunas.
- Tipos: isbn e isbn13 como texto (identificadores, não quantidades).

## A tratar mais tarde
- Título do livro 6549 começa com espaços.
- publication_date ainda está como texto.