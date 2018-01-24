# YAIPL - Yet Another Imperative Programming Language

This is yet another implementation of an imperative programming language (YAIPL). It is a fun project based on the LLVM Ocaml tutorial on [Kaleidoscope](https://llvm.org/docs/tutorial/OCamlLangImpl1.html)
to understand the LLVM infrastructure's internals and its intermediate representation. Contrary to the tutorial, YAIPL's implementation does not implement the lexer and parser in pure Ocaml but rather utilizes ocamllex and menhir. There are two ways to interact with YAIPL. The compiler yaiplc and the REPL yaipl.

Compile yaiplc, yaipl and its stdlib simply with:
``` bash
make
```
To compile your fist YAIPL program:
``` bash
yaiplc.native examples/print_stars.yaipl print_stars
clang++ examples/print_stars_main.cpp stdlib/io.o print_stars.o -o print_stars_main.out
```
And just execute it:

``` bash
./print_stars_main.out 
****************************************************************************************************
```
yaiplc dumps also the llcode:
``` llvm
; ModuleID = 'main'
source_filename = "main"

declare double @putchard(double)

define double @printstar(double %n) {
entry:
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi double [ 1.000000e+00, %entry ], [ %nextvar, %loop ]
  %calltmp = call double @putchard(double 4.200000e+01)
  %nextvar = fadd double %i, 1.000000e+00
  %cmptmp = fcmp ult double %i, %n
  br i1 %cmptmp, label %loop, label %afterloop

afterloop:                                        ; preds = %loop
  ret double 0.000000e+00
}

```
