/// Utility class for calculating drop values
class DropValueCalculator {
  // Pricing constants
  static const double plasticBottleValue = 0.025; // TND per bottle
  static const double aluminumCanValue = 0.06; // TND per can

  /// Calculates the estimated value of a drop based on bottle and can counts
  /// 
  /// Formula: (plasticBottleCount * 0.025) + (cansCount * 0.06)
  /// 
  /// Returns a double with 2 decimal precision.
  /// If values are null or missing, treats them as 0.
  static double calculateEstimatedValue({
    int? plasticBottleCount,
    int? cansCount,
  }) {
    final bottles = plasticBottleCount ?? 0;
    final cans = cansCount ?? 0;
    
    final value = (bottles * plasticBottleValue) + (cans * aluminumCanValue);
    
    // Round to 2 decimal places
    return double.parse(value.toStringAsFixed(2));
  }

  /// Formats the estimated value as a string with currency
  /// 
  /// Example: "Estimated Value: 1.50 TND"
  static String formatEstimatedValue(double value) {
    return '${value.toStringAsFixed(2)} TND';
  }
}
