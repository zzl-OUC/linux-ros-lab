#include <iostream>
#include <string>

int main() {
  int i = 0, j;
  j = ++i;
  std::cout << "after j = ++i : i=" << i << " j=" << j << std::endl;
  j = i++;
  std::cout << "after j = i++ : i=" << i << " j=" << j << std::endl;
  return 0;
}
