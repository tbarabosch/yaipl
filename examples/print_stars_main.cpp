// compile:
// 1.) ./yaiplc.native examples/print_stars.yaipl print_stars
// 2.)  clang++ examples/print_stars_main.cpp stdlib/io.o print_stars.o -o print_stars_main.out

extern "C" {
  double printstar(double);
}

int main() {
  printstar(100);
}
