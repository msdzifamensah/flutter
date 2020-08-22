import 'dart:math';

void main() {
  var n = 0; // number of rabbits
  print('The number of rabbits increases as:\n');

  for (var years = 0; years <= 10; years++) {
    n = calculateRabbit(n, years);
    print('After $years years:\t $n animals');
  }
}

int calculateRabbit(int n, int years) {
  n = (2 * pow(e, log(15) * years)).round().toInt();
  return n;
}
