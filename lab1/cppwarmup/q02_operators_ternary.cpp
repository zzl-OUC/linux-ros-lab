#include <iostream>
#include <string>

int main() {
  int i = 42;
  std::string output = (i < 42) ? "a" : "b";
  std::cout << output << std::endl;
  return 0;
}
