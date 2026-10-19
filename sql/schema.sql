-- Esquema da base de dados goodreads_etl
DROP VIEW IF EXISTS v_ranking;
DROP TABLE IF EXISTS candidatos;
DROP TABLE IF EXISTS livros;

CREATE TABLE livros (
    book_id          INTEGER PRIMARY KEY,
    titulo           TEXT NOT NULL,
    autores          TEXT,
    rating_medio     NUMERIC(3,2),
    isbn             VARCHAR(13),
    isbn13           VARCHAR(13),
    idioma           VARCHAR(10),
    num_paginas      INTEGER,
    num_avaliacoes   INTEGER,
    num_criticas     INTEGER,
    data_publicacao  DATE,
    editora          TEXT
);

CREATE TABLE candidatos (
    book_id            INTEGER PRIMARY KEY REFERENCES livros(book_id),
    ol_work_key        VARCHAR(30),
    num_edicoes        INTEGER,
    genero             VARCHAR(50) NOT NULL,
    pontuacao          NUMERIC(5,3),
    posicao            INTEGER,
    data_carregamento  TIMESTAMP DEFAULT now()
);

CREATE VIEW v_ranking AS
SELECT c.genero, c.posicao, l.titulo, l.autores, l.rating_medio,
       l.num_avaliacoes, c.num_edicoes, c.pontuacao
FROM candidatos c
JOIN livros l ON l.book_id = c.book_id
ORDER BY c.genero, c.posicao;

CREATE TABLE IF NOT EXISTS log_execucoes (
    id                     SERIAL PRIMARY KEY,
    data_hora              TIMESTAMP DEFAULT now(),
    livros_carregados      INTEGER,
    candidatos_carregados  INTEGER,
    estado                 VARCHAR(20),
    mensagem               TEXT
);