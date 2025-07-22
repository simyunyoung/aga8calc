/// Constants used throughout the application
class AppConstants {
  // Standard conditions
  static const double STANDARD_PRESSURE_BAR = 1.01325; // 1 atm in bar
  static const double STANDARD_TEMP_K = 288.15;      // 15°C in Kelvin
  
  // Unit conversion factors
  static const double BAR_TO_BARG_OFFSET = 1.01325;
  static const double CELSIUS_TO_KELVIN_OFFSET = 273.15;
  
  // Validation thresholds
  static const double COMPOSITION_SUM_TOLERANCE = 0.01; // Acceptable deviation from 1.0
  
  // Formatting
  static const int DEFAULT_DECIMAL_PLACES = 5;
  static const int PRESSURE_TEMP_DECIMAL_PLACES = 2;
}