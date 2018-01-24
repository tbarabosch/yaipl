.phony: all
all :
	corebuild -use-menhir -pkg llvm -pkg llvm.executionengine -pkg llvm.scalar_opts -pkg llvm.target -pkg llvm.analysis -pkg llvm.all_backends src/yaiplc.native
	corebuild -use-menhir -pkg llvm -pkg llvm.executionengine -pkg llvm.scalar_opts -pkg llvm.target -pkg llvm.analysis src/yaipl.native 
 clang -c stdlib/io.c -o stdlib/io.o

clean :
	rm -rf _build
	rm *.native
