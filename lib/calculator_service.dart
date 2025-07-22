import 'package:aga8_calc_app/aga8_service.dart';
import 'package:aga8_calc_app/constants.dart';

/// Service class for handling AGA8 calculations with caching
class CalculatorService {
  // Cache for storing calculation results
  static final Map<String, AGA8Result> _cache = {};
  
  /// Calculates AGA8 properties for specified conditions
  /// 
  /// [composition] is a list of mole fractions for the 21 components
  /// [pressure] is the pressure in the specified unit
  /// [temperature] is the temperature in the specified unit
  /// [isPressureBarg] indicates if pressure is in bar(g) instead of bar(a)
  /// [isTempCelsius] indicates if temperature is in °C instead of K
  static AGA8Result? calculateForConditions(
    List<double> composition, 
    double pressure, 
    double temperature, 
    bool isPressureBarg, 
    bool isTempCelsius
  ) {
    // Convert to absolute units for calculation
    final pressureAbs = isPressureBarg 
        ? pressure + AppConstants.BAR_TO_BARG_OFFSET 
        : pressure;
    final tempK = isTempCelsius 
        ? temperature + AppConstants.CELSIUS_TO_KELVIN_OFFSET 
        : temperature;
    
    // Check cache first
    final cacheKey = _generateCacheKey(composition, pressureAbs, tempK);
    final cachedResult = _cache[cacheKey];
    if (cachedResult != null) {
      print('Using cached result for $cacheKey');
      return cachedResult;
    }
    
    // Calculate if not in cache
    final result = AGA8Service.calculate(composition, pressureAbs, tempK);
    
    // Cache the result if valid
    if (result != null) {
      _cache[cacheKey] = result;
    }
    
    return result;
  }
  
  /// Calculates AGA8 properties for standard conditions (1 atm, 15°C)
  /// 
  /// [composition] is a list of mole fractions for the 21 components
  static AGA8Result? calculateForStandardConditions(List<double> composition) {
    // Check if composition is valid
    if (!_isCompositionValid(composition)) {
      return null;
    }
    
    // Check cache first
    final cacheKey = _generateCacheKey(
      composition, 
      AppConstants.STANDARD_PRESSURE_BAR, 
      AppConstants.STANDARD_TEMP_K
    );
    final cachedResult = _cache[cacheKey];
    if (cachedResult != null) {
      print('Using cached standard conditions result');
      return cachedResult;
    }
    
    // Calculate if not in cache
    final result = AGA8Service.calculate(
      composition, 
      AppConstants.STANDARD_PRESSURE_BAR, 
      AppConstants.STANDARD_TEMP_K
    );
    
    // Cache the result if valid
    if (result != null) {
      _cache[cacheKey] = result;
    }
    
    return result;
  }
  
  /// Validates if the composition is valid for calculation
  /// 
  /// [composition] is a list of mole fractions for the 21 components
  static bool _isCompositionValid(List<double> composition) {
    if (composition.isEmpty) {
      return false;
    }
    
    final sum = composition.fold(0.0, (sum, value) => sum + value);
    return (sum - 1.0).abs() <= AppConstants.COMPOSITION_SUM_TOLERANCE;
  }
  
  /// Generates a cache key for the given parameters
  static String _generateCacheKey(
    List<double> composition, 
    double pressure, 
    double temperature
  ) {
    // Round values to reduce cache size while maintaining precision
    final roundedPressure = pressure.toStringAsFixed(4);
    final roundedTemp = temperature.toStringAsFixed(4);
    
    // Use a simplified composition string to avoid excessive key length
    final compositionStr = composition.map((v) => v.toStringAsFixed(6)).join('_');
    
    return '$compositionStr|$roundedPressure|$roundedTemp';
  }
  
  /// Clears the calculation cache
  static void clearCache() {
    _cache.clear();
    print('Calculation cache cleared');
  }
}