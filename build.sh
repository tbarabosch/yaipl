#!/bin/bash
echo "Building compiler."
corebuild -use-menhir -package llvm src/yaipl.native 
