import 'dart:math';

class CodeGenerator {
 static String generateUniqueCode(String startCode) {
  final now = DateTime.now();
  final yyMMdd = '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  final rand = Random();
  final random3 = List.generate(3, (_) => rand.nextInt(10)).join();

  return '$startCode-$yyMMdd-$random3';
}
}
