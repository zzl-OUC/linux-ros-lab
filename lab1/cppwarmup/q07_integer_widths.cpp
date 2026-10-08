#include <iostream>
#include <limits>

template <typename T>
void show(const char* n) {
  std::cout << n << ": sizeof=" << sizeof(T) << " bytes, bits=" << sizeof(T) * 8
            << ", min=" << std::numeric_limits<T>::min()
            << ", max=" << std::numeric_limits<T>::max() << std::endl;
}

int main() {
  show<short>("short");
  show<int>("int");
  show<long>("long");
  show<long long>("long long");
  return 0;
}
