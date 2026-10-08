#include <iostream>
#include <string>

int main() {
  int i = 42;
  int* j = &i;
  *j = *j * *j;
  std::cout << *j << std::endl;
  std::cout << "i is now " << i << std::endl;
  return 0;
}
