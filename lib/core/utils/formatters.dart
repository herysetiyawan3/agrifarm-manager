import 'package:intl/intl.dart';

class Formatters {
  // Format currency into Indonesian Rupiah (e.g. Rp 150.000)
  static String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format currency into a shorter form (e.g. Rp 150k, Rp 12.5M)
  static String formatShortRupiah(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return formatRupiah(amount);
  }

  // Format date into Indonesian standard format (e.g. 7 Jun 2026)
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  // Format date into long Indonesian standard (e.g. Minggu, 7 Juni 2026)
  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  // Calculate days difference (HST - Hari Setelah Tanam)
  static int calculateHST(DateTime plantingDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final plantDay = DateTime(plantingDate.year, plantingDate.month, plantingDate.day);
    final difference = today.difference(plantDay).inDays;
    return difference >= 0 ? difference : 0;
  }
}
