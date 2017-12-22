# YAIPL - Yet Another Imperative Programming Language

This is yet another implementation of an imperative programming language (YAIPL). It is a fun project based on the LLVM Ocaml tutorial on [Kaleidoscope](https://llvm.org/docs/tutorial/OCamlLangImpl1.html)
to understand the LLVM infrastructure's internals and its intermediate representation. Contrary to the tutorial, YAIPL's implementation does not implement the lexer and parser in pure Ocaml but rather utilizes ocamllex and menhir.