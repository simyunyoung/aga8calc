import 'package:flutter/material.dart';
import 'package:aga8_calc_app/aga8_service.dart';
import 'package:aga8_calc_app/gas_composition_input.dart';
import 'package:aga8_calc_app/constants.dart';
import 'package:aga8_calc_app/calculator_service.dart';
import 'package:flutter/services.dart'; // For Clipboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AGA8Service.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGA8 Gas Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Use constants from the constants.dart file
  
  AGA8Result? _result;
  List<double> _composition = [];
  double _pressure = 100.0;
  double _temperature = 25.0; // Default to 25°C
  bool _isPressureBarg = true; // Default to bar(g)
  bool _isTempCelsius = true; // Default to °C
  double _compositionSum = 0.0; // To track the sum of composition

  AGA8Result? _standardResult; // Result at standard conditions

  // Calculate results at standard conditions
  AGA8Result? _calculateStandardConditions(List<double> composition) {
    // Use the CalculatorService to handle validation and caching
    return CalculatorService.calculateForStandardConditions(composition);
  }

  void _calculate() {
    // Validate composition before calculation
    if (_composition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter gas composition values')),
      );
      return;
    }
    
    // Use CalculatorService to handle unit conversions, validation, and caching
    final result = CalculatorService.calculateForConditions(
      _composition, 
      _pressure, 
      _temperature, 
      _isPressureBarg, 
      _isTempCelsius
    );
    
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculation failed. Please check your inputs.')),
      );
      return;
    }
    
    // Calculate at standard conditions using the dedicated method
    final standardResult = _calculateStandardConditions(_composition);
    
    setState(() {
      _result = result;
      _standardResult = standardResult;
    });
    
    // Show error message if calculation had errors
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(result.error!))),
      );
    }
  }

  // Utility method to format numeric values consistently
  String _formatNumber(double value, {int? decimalPlaces}) {
    return value.toStringAsFixed(decimalPlaces ?? AppConstants.DEFAULT_DECIMAL_PLACES);
  }

  // Helper method to convert AGA8Error enum to user-friendly message
  String _getErrorMessage(AGA8Error error) {
    switch (error) {
      case AGA8Error.invalidComposition:
        return 'Invalid gas composition. Please ensure all components sum to 1.0 (100%).'; 
      case AGA8Error.invalidPressure:
        return 'Invalid pressure value. Pressure must be positive.'; 
      case AGA8Error.invalidTemperature:
        return 'Invalid temperature value. Temperature must be positive in Kelvin.'; 
      case AGA8Error.calculationError:
        return 'Error during calculation. Please check input values.'; 
      case AGA8Error.unknown:
        return 'An unknown error occurred during calculation.'; 
    }
  }

  void _copyResults() {
    if (_result != null) {
      final String pressureText = _isPressureBarg 
          ? "${_formatNumber(_pressure, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(g)" 
          : "${_formatNumber(_pressure, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(a)";
      final String tempText = _isTempCelsius 
          ? "${_formatNumber(_temperature, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} °C" 
          : "${_formatNumber(_temperature, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} K";
      
      String resultsText = '''
At Specified Conditions ($pressureText, $tempText):
''';

      // Add error information if present
      if (_result!.error != null) {
        resultsText += 'Error: ${_getErrorMessage(_result!.error!)}\n';
      }
      
      resultsText += '''
Z-Factor: ${_formatNumber(_result!.zFactor)}
Gas Density: ${_formatNumber(_result!.gasDensity)} kg/m³
Molar Mass: ${_formatNumber(_result!.molarMass)} g/mol
Speed of Sound: ${_formatNumber(_result!.speedOfSound)} m/s
''';
      
      if (_standardResult != null) {
        resultsText += '''

At Standard Conditions (${_formatNumber(AppConstants.STANDARD_PRESSURE_BAR, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(a), ${_formatNumber(AppConstants.STANDARD_TEMP_K - AppConstants.CELSIUS_TO_KELVIN_OFFSET, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} °C):
''';
        
        // Add standard conditions error information if present
        if (_standardResult!.error != null) {
          resultsText += 'Error: ${_getErrorMessage(_standardResult!.error!)}\n';
        }
        
        resultsText += '''
Z-Factor: ${_formatNumber(_standardResult!.zFactor)}
Gas Density: ${_formatNumber(_standardResult!.gasDensity)} kg/m³
Molar Mass: ${_formatNumber(_standardResult!.molarMass)} g/mol
Speed of Sound: ${_formatNumber(_standardResult!.speedOfSound)} m/s
''';
      }
      
      Clipboard.setData(ClipboardData(text: resultsText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompositionNormalized = (_compositionSum - 1.0).abs() < AppConstants.COMPOSITION_SUM_TOLERANCE;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGA8 Gas Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model: AGA8 Detail', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Gas Composition (Mole %)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Warning message for composition
                    if (!isCompositionNormalized)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Warning: Composition sum is not 1 (or 100%). Current sum: ${_compositionSum.toStringAsFixed(3)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    SizedBox(
                      height: 300, // Fixed height for composition input
                      child: GasCompositionInput(
                        onChanged: (composition) {
                          setState(() {
                            _composition = composition;
                          });
                        },
                        onSumChanged: (sum) {
                          setState(() {
                            _compositionSum = sum;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pressure', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _pressure.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _pressure = double.tryParse(value) ?? 0.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ToggleButtons(
                          isSelected: [_isPressureBarg, !_isPressureBarg],
                          onPressed: (index) {
                            setState(() {
                              _isPressureBarg = index == 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('bar(g)')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('bar(a)'))],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Temperature', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _temperature.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _temperature = double.tryParse(value) ?? 0.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ToggleButtons(
                          isSelected: [_isTempCelsius, !_isTempCelsius],
                          onPressed: (index) {
                            setState(() {
                              _isTempCelsius = index == 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('°C')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('K'))],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                        child: const Text('Calculate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calculation Results', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      
                      // Display error message if there is an error
                      if (_result!.error != null) ...[  
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getErrorMessage(_result!.error!),
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Text(
                        'At Specified Conditions (${_isPressureBarg ? "${_formatNumber(_pressure, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(g)" : "${_formatNumber(_pressure, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(a)"}, ${_isTempCelsius ? "${_formatNumber(_temperature, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} °C" : "${_formatNumber(_temperature, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} K"}):', 
                        style: Theme.of(context).textTheme.titleMedium
                      ),
                      const SizedBox(height: 8),
                      Text('Z-Factor: ${_formatNumber(_result!.zFactor)}'),
                      Text('Gas Density: ${_formatNumber(_result!.gasDensity)} kg/m³'),
                      Text('Molar Mass: ${_formatNumber(_result!.molarMass)} g/mol'),
                      Text('Speed of Sound: ${_formatNumber(_result!.speedOfSound)} m/s'),
                      const SizedBox(height: 16),
                      
                      if (_standardResult != null) ...[  
                        // Display standard conditions error if there is one
                        if (_standardResult!.error != null) ...[  
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Standard conditions: ${_getErrorMessage(_standardResult!.error!)}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        Text(
                          'At Standard Conditions (${_formatNumber(AppConstants.STANDARD_PRESSURE_BAR, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} bar(a), ${_formatNumber(AppConstants.STANDARD_TEMP_K - AppConstants.CELSIUS_TO_KELVIN_OFFSET, decimalPlaces: AppConstants.PRESSURE_TEMP_DECIMAL_PLACES)} °C):', 
                          style: Theme.of(context).textTheme.titleMedium
                        ),
                        const SizedBox(height: 8),
                        Text('Z-Factor: ${_formatNumber(_standardResult!.zFactor)}'),
                        Text('Gas Density: ${_formatNumber(_standardResult!.gasDensity)} kg/m³'),
                        Text('Molar Mass: ${_formatNumber(_standardResult!.molarMass)} g/mol'),
                        Text('Speed of Sound: ${_formatNumber(_standardResult!.speedOfSound)} m/s'),
                        const SizedBox(height: 16),
                      ],
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _copyResults,
                          child: const Text('Copy All Results'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
