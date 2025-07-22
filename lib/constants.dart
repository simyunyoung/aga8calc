/// Constants used throughout the application
class AppConstants {
  // Standard conditions
  static const double standardPressureBar = 1.01325; // 1 atm in bar
  static const double standardTempK = 288.15;      // 15°C in Kelvin
  // Unit conversion factors
  static const double barToBargOffset = 1.01325;
  static const double celsiusToKelvinOffset = 273.15;
  // Validation thresholds
  static const double compositionSumTolerance = 0.01; // Acceptable deviation from 1.0
  // Formatting
  static const int defaultDecimalPlaces = 5;
  static const int pressureTempDecimalPlaces = 2;
}