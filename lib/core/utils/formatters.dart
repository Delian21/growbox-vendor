String formatCurrency(double amount) {
  final parts = amount.toStringAsFixed(0).split('.');
  final wholePart = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < wholePart.length; i++) {
    if (i > 0 && (wholePart.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(wholePart[i]);
  }
  return '\u20A6${buffer.toString()}';
}

String formatNumber(double value) {
  final parts = value.toStringAsFixed(0).split('.');
  final wholePart = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < wholePart.length; i++) {
    if (i > 0 && (wholePart.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(wholePart[i]);
  }
  return buffer.toString();
}