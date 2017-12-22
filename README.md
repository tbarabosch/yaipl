# YAIPL - Yet Another Imperative Programming Language

This is yet another implementation of an imperative programming language (YAIPL). It is a fun project based on the LLVM Ocaml tutorial on [Kaleidoscope](https://llvm.org/docs/tutorial/OCamlLangImpl1.html)
to understand the LLVM infrastructure's internals and its intermediate representation. Contrary to the tutorial, YAIPL's implementation does not implement the lexer and parser in pure Ocaml but rather utilizes ocamllex and menhir.

Compile it and test it as follows:
``` bash
./build.sh
./yaipl.native 
ready> extern cos(x); extern tan(z); def crazy_math(a b c) a*a + b - c + a * b * c; crazy_math(cos(4), tan(0.42), 0.4 * 42); 
```

This should generate the following LLVM IR:
``` bash

declare double @cos(double %x)

declare double @tan(double %z)

define double @crazy_math(double %a, double %b, double %c) {
entry:
  %multmp = fmul double %a, %a
  %addtmp = fadd double %multmp, %b
  %subtmp = fsub double %addtmp, %c
  %multmp1 = fmul double %a, %b
  %multmp2 = fmul double %multmp1, %c
  %addtmp3 = fadd double %subtmp, %multmp2
  ret double %addtmp3
}
  %calltmp5 = call double @crazy_math(double %calltmp, double %calltmp4, double 1.680000e+01)
```

