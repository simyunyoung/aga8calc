import 'dart:js_util';
import 'dart:typed_data'; // Import for Float64List

/// Enum representing possible errors in AGA8 calculations
enum AGA8Error {
  /// The gas composition is invalid (e.g., empty, negative values, or sum != 1.0)
  invalidComposition,
  
  /// The pressure value is invalid (e.g., negative or zero)
  invalidPressure,
  
  /// The temperature value is invalid (e.g., negative or zero)
  invalidTemperature,
  
  /// An error occurred during the calculation
  calculationError,
  
  /// An unknown error occurred
  unknown
}

/// Service for interfacing with the AGA8 WASM module
/// Handles the JavaScript interop for AGA8 calculations
/// Service for calculating gas properties using the AGA8 Detail Characterization method
/// 
/// This service provides methods to initialize the WASM module and calculate
/// gas properties based on composition, pressure, and temperature.
/// It uses JavaScript interop to call the WASM module through a bridge.
class AGA8Service {
  /// Initializes the AGA8 WASM module
  /// 
  /// This method must be called before any calculations can be performed.
  /// It initializes the WebAssembly module that contains the AGA8 implementation.
  /// 
  /// Throws an exception if initialization fails.
  static Future<void> init() async {
    // The WASM module is now initialized by aga8_bridge.js
    // No action needed here.
  }

  /// Calculates AGA8 properties for a gas mixture
  /// 
  /// [composition] is a list of mole fractions for the 21 components
  /// [pressure] is the absolute pressure in bar
  /// [temperature] is the temperature in Kelvin
  /// 
  /// Returns an AGA8Result object containing the calculated properties,
  /// or null if the calculation fails
  static AGA8Result? calculate(List<double> composition, double pressure, double temperature) {
    // Validate inputs
    if (composition.isEmpty) {
      // Invalid composition: empty list
      return AGA8Result(
        zFactor: 0, 
        gasDensity: 0, 
        molarMass: 0, 
        speedOfSound: 0,
        error: AGA8Error.invalidComposition
      );
    }
    
    if (pressure <= 0) {
      // Invalid pressure (must be positive)
      return AGA8Result(
        zFactor: 0, 
        gasDensity: 0, 
        molarMass: 0, 
        speedOfSound: 0,
        error: AGA8Error.invalidPressure
      );
    }
    
    if (temperature <= 0) {
      // Invalid temperature (must be positive)
      return AGA8Result(
        zFactor: 0, 
        gasDensity: 0, 
        molarMass: 0, 
        speedOfSound: 0,
        error: AGA8Error.invalidTemperature
      );
    }

    // Convert Dart List<double> to Float64List for JavaScript interop
    final jsComposition = Float64List.fromList(composition);

  // Calculating with composition and conditions

    dynamic result;
    try {
      // Call the calculate method on the global aga8Bridge object
      result = callMethod(getProperty(globalThis, 'aga8Bridge'), 'calculate', [jsComposition, pressure, temperature]);
  // Result from JS
    } catch (e) {
  // Error calling WASM
      // If an error occurs during the JavaScript call, return error result
      return AGA8Result(
        zFactor: 0, 
        gasDensity: 0, 
        molarMass: 0, 
        speedOfSound: 0,
        error: AGA8Error.calculationError
      );
    }

    if (result != null) {
      final aga8Result = AGA8Result.fromJS(result);
  // Parsed result
      return aga8Result;
    }
    
    print('Result was null');
    return AGA8Result(
      zFactor: 0, 
      gasDensity: 0, 
      molarMass: 0, 
      speedOfSound: 0,
      error: AGA8Error.unknown
    );
  }
}

/// Represents the result of an AGA8 calculation
/// 
/// Contains the calculated properties of the gas mixture
/// and an optional error if the calculation failed
class AGA8Result {
  /// The compressibility factor (dimensionless)
  final double zFactor;
  
  /// The gas density in kg/m³
  final double gasDensity;
  
  /// The molar mass in g/mol
  final double molarMass;
  
  /// The speed of sound in m/s
  final double speedOfSound;
  
  /// The error that occurred during calculation, if any
  final AGA8Error? error;

  /// Creates a new AGA8Result
  /// 
  /// [zFactor] is the compressibility factor (dimensionless)
  /// [gasDensity] is the gas density in kg/m³
  /// [molarMass] is the molar mass in g/mol
  /// [speedOfSound] is the speed of sound in m/s
  /// [error] is the error that occurred during calculation, if any
  AGA8Result({
    required this.zFactor,
    required this.gasDensity,
    required this.molarMass,
    required this.speedOfSound,
    this.error,
  });
  
  @override
  String toString() {
    return 'AGA8Result{zFactor: $zFactor, gasDensity: $gasDensity, molarMass: $molarMass, speedOfSound: $speedOfSound, error: $error}';
  }

  /// Creates an AGA8Result from a JavaScript object returned by the WASM module
  /// 
  /// [jsObject] is the JavaScript object returned by the WASM module
  /// Returns an AGA8Result with the properties from the JavaScript object
  factory AGA8Result.fromJS(dynamic jsObject) {
  // Creating AGA8Result from JS object
    
    // Check if properties exist and provide default values if they don't
    double getDoubleProperty(dynamic obj, String prop) {
      try {
  // Getting property
        var value = getProperty(obj, prop);
  // Property value
        return value == null ? 0.0 : (value is double ? value : double.parse(value.toString()));
      } catch (e) {
  // Error getting property
        return 0.0;
      }
    }
    
    // Check for error property in the JS object
    AGA8Error? error;
    try {
      final errorStr = getProperty(jsObject, 'error');
      if (errorStr != null) {
        // Map error string to enum value
        switch(errorStr.toString().toLowerCase()) {
          case 'invalid_composition':
            error = AGA8Error.invalidComposition;
            break;
          case 'invalid_pressure':
            error = AGA8Error.invalidPressure;
            break;
          case 'invalid_temperature':
            error = AGA8Error.invalidTemperature;
            break;
          case 'calculation_error':
            error = AGA8Error.calculationError;
            break;
          default:
            if (errorStr.toString().isNotEmpty) {
              error = AGA8Error.unknown;
              // Unknown error from WASM
            }
        }
      }
    } catch (e) {
  // Error checking for error property
    }
    
    final result = AGA8Result(
      zFactor: getDoubleProperty(jsObject, 'z_factor'),
      gasDensity: getDoubleProperty(jsObject, 'gas_density_kg_m3'),
      molarMass: getDoubleProperty(jsObject, 'molar_mass_g_mol'),
      speedOfSound: getDoubleProperty(jsObject, 'speed_of_sound_m_s'),
      error: error,
    );
    
  // Created AGA8Result
    return result;
  }
}
