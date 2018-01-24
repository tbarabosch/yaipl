// taken from https://llvm.org/docs/tutorial/LangImpl08.html
// compile:
// 1.) ./yaiplc.native examples/average.yaipl average
// 2.) clang++ examples/test_skeleton.cpp average.o -o average.out
#include <iostream>

extern "C" {
    double average(double, double);
}

int main() {
    std::cout << "average of 3.0 and 4.0: " << average(3.0, 4.0) << std::endl;
}
