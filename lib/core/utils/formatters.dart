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

/// dd/mm/yyyy — the order Nigerian vendors read dates in. Shared so every page
/// that shows a calendar date renders it the same way, zero-padded, so
/// "04/03/2026" can never be mistaken for the 3rd of April.
String formatDateDdMmYyyy(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Relative time for order rows — "Just now" / "2 min ago" /
/// "3 hours ago" / "2 days ago". Shared by the dashboard's Recent Orders
/// and the Orders table so both pages phrase the same instant alike.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  }
  return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
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