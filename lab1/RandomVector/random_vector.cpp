#include "random_vector.h"
#include <cstdlib>  // rand(), srand(), RAND_MAX

RandomVector::RandomVector(int size, double max_val) {
  vect.resize(size);
  for (int k = 0; k < size; ++k) {
    // rand() is deterministic once srand() has been called in main.cpp
    vect[k] = static_cast<double>(rand()) / RAND_MAX * max_val;
  }
}

void RandomVector::print() {
  for (size_t k = 0; k < vect.size(); ++k) {
    std::cout << vect[k] << " ";
  }
  std::cout << std::endl;
}

double RandomVector::mean() {
  double sum = 0.0;
  for (size_t k = 0; k < vect.size(); ++k) {
    sum += vect[k];
  }
  return sum / static_cast<double>(vect.size());
}

double RandomVector::max() {
  double m = vect[0];
  for (size_t k = 1; k < vect.size(); ++k) {
    if (vect[k] > m) m = vect[k];
  }
  return m;
}

double RandomVector::min() {
  double m = vect[0];
  for (size_t k = 1; k < vect.size(); ++k) {
    if (vect[k] < m) m = vect[k];
  }
  return m;
}

void RandomVector::printHistogram(int bins) {
  double lo = min();
  double hi = max();
  double width = (hi - lo) / static_cast<double>(bins);

  int* counts = new int[bins];
  for (int b = 0; b < bins; ++b) counts[b] = 0;

  for (size_t k = 0; k < vect.size(); ++k) {
    int b = static_cast<int>((vect[k] - lo) / width);
    if (b >= bins) b = bins - 1;  // the value equal to max() falls one bin past the end
    counts[b] += 1;
  }

  int tallest = 0;
  for (int b = 0; b < bins; ++b) {
    if (counts[b] > tallest) tallest = counts[b];
  }

  for (int level = tallest; level >= 1; --level) {
    for (int b = 0; b < bins; ++b) {
      std::cout << (counts[b] >= level ? "***" : "   ") << " ";
    }
    std::cout << std::endl;
  }
  delete[] counts;
}
