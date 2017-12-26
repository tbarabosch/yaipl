# YAIPL - Yet Another Imperative Programming Language

This is yet another implementation of an imperative programming language (YAIPL). It is a fun project based on the LLVM Ocaml tutorial on [Kaleidoscope](https://llvm.org/docs/tutorial/OCamlLangImpl1.html)
to understand the LLVM infrastructure's internals and its intermediate representation. Contrary to the tutorial, YAIPL's implementation does not implement the lexer and parser in pure Ocaml but rather utilizes ocamllex and menhir.

Compile it and test it as follows:
``` bash
./build.sh
./yaipl.native 
ready> def fib(x)
  begin
    if x < 3 then
      1
    else
      fib(x-1)+fib(x-2)
  end

fib (20);
```

This should generate the following LLVM IR:
``` bash
define double @fib(double %x) {
entry:
  %cmptmp = fcmp ult double %x, 3.000000e+00
  br i1 %cmptmp, label %ifcont, label %else

else:                                             ; preds = %entry
  %subtmp = fadd double %x, -1.000000e+00
  %calltmp = call double @fib(double %subtmp)
  %subtmp1 = fadd double %x, -2.000000e+00
  %calltmp2 = call double @fib(double %subtmp1)
  %addtmp = fadd double %calltmp, %calltmp2
  br label %ifcont

ifcont:                                           ; preds = %entry, %else
  %iftmp = phi double [ %addtmp, %else ], [ 1.000000e+00, %entry ]
  ret double %iftmp
}
  %calltmp3 = call double @fib(double 2.000000e+01)

```
