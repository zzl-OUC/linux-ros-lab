void reset(int& i) { i = 0; }

#include <iostream>
#include <string>

int main() {
  int j = 42;
  reset(j);
  std::cout << j << std::endl;
  return 0;
}
