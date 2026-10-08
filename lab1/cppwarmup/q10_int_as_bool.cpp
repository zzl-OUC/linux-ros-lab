#include <iostream>
#include <string>

int main() {
  int i = 42;
  if (i) {
    i = 0;
  } else {
    i = 43;
  }
  std::cout << "i = " << i << std::endl;
  int k = 0;
  if (k) { k = 100; } else { k = 43; }
  std::cout << "control k = " << k << std::endl;
  return 0;
}
