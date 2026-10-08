#include <iostream>
#include <string>

int main() {
  int i;          // uninitialized, but assigned before any read
  int& ri = i;
  i = 5;
  ri = 10;
  std::cout << i << " " << ri << std::endl;
  return 0;
}
