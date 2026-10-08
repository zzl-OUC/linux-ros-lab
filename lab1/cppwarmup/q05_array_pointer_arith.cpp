#include <iostream>
#include <string>

int main() {
  int i[4] = {42, 24, 42, 24};
  *(i + 2) = *(i + 1) - i[3];
  std::cout << *(i + 2) << std::endl;
  std::cout << "whole array: ";
  for (int k = 0; k < 4; ++k) std::cout << i[k] << " ";
  std::cout << std::endl;
  return 0;
}
