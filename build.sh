#!/bin/bash
echo "Building compiler."
corebuild -use-menhir -pkg llvm -pkg llvm.executionengine -pkg llvm.scalar_opts -pkg llvm.target -pkg llvm.analysis src/yaipl.native 
