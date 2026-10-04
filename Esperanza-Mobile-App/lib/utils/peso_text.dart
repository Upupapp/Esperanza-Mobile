/// An amount as the API sends it ("4000.00", 4000, "4000") written for a
/// resident: "₱4,000.00". Null when there is no amount to show.
String? pesoText(Object? amount) {
  if (amount == null) return null;
  final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString().trim());
  if (value == null) return null;
  final fixed = value.abs().toStringAsFixed(2);
  final whole = fixed.substring(0, fixed.length - 3);
  final cents = fixed.substring(fixed.length - 3);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '${value < 0 ? '-' : ''}₱$grouped$cents';
}
