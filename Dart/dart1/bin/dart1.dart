import 'package:dart1/dart1.dart' as dart1;
import 'dart:math';

void main() {
  var n = 0; // number of rabbits
  print('The number of rabbits increases as:\n');

  for (var years = 0; years <= 10; years++) {
    n = (2 * pow(e, log(15) * years)).round().toInt();
    print('After $years years:\t $n animals');
  }
}
