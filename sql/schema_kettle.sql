CREATE SCHEMA IF NOT EXISTS kettle;

CREATE TABLE IF NOT EXISTS kettle.livros (
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

CREATE TABLE IF NOT EXISTS kettle.candidatos (
    book_id            INTEGER PRIMARY KEY REFERENCES kettle.livros(book_id),
    ol_work_key        VARCHAR(30),
    num_edicoes        INTEGER,
    tem_edicao_pt      VARCHAR(15),
    data_carregamento  TIMESTAMP DEFAULT now()
);