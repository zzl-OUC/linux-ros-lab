#include <iostream>
#include <string>

int main() {
  unsigned char c = -1;
  std::cout << "unsigned char c = -1  ->  c = " << static_cast<int>(c) << std::endl;
  signed char s = -1;
  std::cout << "signed char s = -1    ->  s = " << static_cast<int>(s) << std::endl;
  unsigned char u = 255;
  ++u;
  std::cout << "unsigned char 255 + 1 ->    " << static_cast<int>(u) << std::endl;
  std::cout << "sizeof(unsigned char) = " << sizeof(unsigned char) << std::endl;
  return 0;
}
