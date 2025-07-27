import 'package:flutter/material.dart';
import 'package:aga8_calc_app/aga8_service.dart';
import 'package:aga8_calc_app/gas_composition_input.dart';
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
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
  AGA8Result? _result;
  AGA8Result? _standardResult;
  List<double> _composition = [];
  double _pressure = 90.0;
  double _temperature = 30.0; // Default to 30°C
  bool _isPressureBarg = true; // Default to bar(g)
  bool _isTempCelsius = true; // Default to °C
  double _compositionSum = 0.0; // To track the sum of composition

  void _calculate() {
    // No SnackBar here, warning is now visual
    final pressureAbs = _isPressureBarg ? _pressure + 1.01325 : _pressure;
    final tempK = _isTempCelsius ? _temperature + 273.15 : _temperature;

    final result = AGA8Service.calculate(_composition, pressureAbs, tempK);
    // Standard conditions: 1 atm (1.01325 bar), 15°C (288.15 K)
    final standardResult = AGA8Service.calculate(_composition, 1.01325, 288.15);
    setState(() {
      _result = result;
      _standardResult = standardResult;
    });
  }

  void _copyResults() {
    if (_result != null) {
      final String resultsText = '''
Z-Factor: ${_result!.zFactor.toStringAsFixed(5)}
Gas Density: ${_result!.gasDensity.toStringAsFixed(5)} kg/m³
Molar Mass: ${_result!.molarMass.toStringAsFixed(5)} g/mol
Speed of Sound: ${_result!.speedOfSound.toStringAsFixed(5)} m/s
''';
      Clipboard.setData(ClipboardData(text: resultsText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompositionNormalized = (_compositionSum - 1.0).abs() < 1e-6;

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
                          _composition = composition;
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _result == null
                    ? Center(
                        child: Text(
                          'Calculation results will appear here after you click Calculate.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main result column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Calculation Results', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 16),
                                Text('Input Pressure: '
                                    '${_isPressureBarg ? (_pressure + 1.01325).toStringAsFixed(3) : _pressure.toStringAsFixed(3)} bar'),
                                Text('Input Temperature: '
                                    '${_isTempCelsius ? (_temperature + 273.15).toStringAsFixed(2) : _temperature.toStringAsFixed(2)} K'),
                                const SizedBox(height: 8),
                                Text('Z-Factor: ${_result!.zFactor.toStringAsFixed(5)}'),
                                Text('Gas Density: ${_result!.gasDensity.toStringAsFixed(5)} kg/m³'),
                                Text('Molar Mass: ${_result!.molarMass.toStringAsFixed(5)} g/mol'),
                                Text('Speed of Sound: ${_result!.speedOfSound.toStringAsFixed(5)} m/s'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Standard condition column
                          if (_standardResult != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Standard Condition', style: Theme.of(context).textTheme.titleLarge),
                                  Text('(1 atm, 15°C)', style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 16),
                                  Text('Z-Factor: ${_standardResult!.zFactor.toStringAsFixed(5)}'),
                                  Text('Gas Density: ${_standardResult!.gasDensity.toStringAsFixed(5)} kg/m³'),
                                  Text('Molar Mass: ${_standardResult!.molarMass.toStringAsFixed(5)} g/mol'),
                                  Text('Speed of Sound: ${_standardResult!.speedOfSound.toStringAsFixed(5)} m/s'),
                                ],
                              ),
                            ),
                          // Copy button at the bottom right
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                              child: ElevatedButton(
                                onPressed: _copyResults,
                                child: const Text('Copy All Results'),
                              ),
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