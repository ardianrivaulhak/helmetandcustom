String formatCurrency(double amount) {
  String result = amount.toStringAsFixed(0);
  // Add thousand separators with dot
  final chars = result.split('');
  String formatted = '';
  int count = 0;
  for (int i = chars.length - 1; i >= 0; i--) {
    formatted = chars[i] + formatted;
    count++;
    if (count % 3 == 0 && i != 0) {
      formatted = '.$formatted';
    }
  }
  return 'IDR $formatted';
}
