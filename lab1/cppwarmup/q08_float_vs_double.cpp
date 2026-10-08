#include <iostream>
#include <limits>
#include <iomanip>

int main() {
  std::cout << "float  : sizeof=" << sizeof(float)
            << " decimal digits guaranteed = " << std::numeric_limits<float>::digits10 << std::endl;
  std::cout << "double : sizeof=" << sizeof(double)
            << " decimal digits guaranteed = " << std::numeric_limits<double>::digits10 << std::endl;
  float f = 0.1f;
  double d = 0.1;
  std::cout << std::setprecision(17);
  std::cout << "0.1 stored in float  = " << f << std::endl;
  std::cout << "0.1 stored in double = " << d << std::endl;
  std::cout << "1e20 as float  = " << static_cast<float>(1e20) << std::endl;
  std::cout << "1e20 as double = " << static_cast<double>(1e20) << std::endl;
  int i;
  i = 3.14;
  std::cout << "int i; i = 3.14;  ->  i = " << i << std::endl;
  return 0;
}
