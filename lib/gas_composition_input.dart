import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard

enum CompositionUnit {
  moleFraction,
  molePercentage,
  massPercentage,
}

class GasCompositionInput extends StatefulWidget {
  final Function(List<double>) onChanged;
  final Function(double) onSumChanged; // New callback for sum

  const GasCompositionInput({super.key, required this.onChanged, required this.onSumChanged});

  @override
  State<GasCompositionInput> createState() => _GasCompositionInputState();
}

class _GasCompositionInputState extends State<GasCompositionInput> {
  final List<TextEditingController> _controllers = List.generate(21, (index) => TextEditingController());
  final List<String> _componentNames = [
    'Methane', 'Nitrogen', 'Carbon Dioxide', 'Ethane', 'Propane',
    'Isobutane', 'n-Butane', 'Isopentane', 'n-Pentane', 'n-Hexane',
    'n-Heptane', 'n-Octane', 'n-Nonane', 'n-Decane', 'Hydrogen',
    'Oxygen', 'Carbon Monoxide', 'Water', 'Hydrogen Sulfide', 'Helium',
    'Argon'
  ];

  // Abbreviations for each component, matching the order of _componentNames
  final List<String> _componentAbbreviations = [
    'CH₄', 'N₂', 'CO₂', 'C₂H₆', 'C₃H₈',
    'i-C₄H₁₀', 'n-C₄H₁₀', 'i-C₅H₁₂', 'n-C₅H₁₂', 'C₆H₁₄',
    'C₇H₁₆', 'C₈H₁₈', 'C₉H₂₀', 'C₁₀H₂₂', 'H₂',
    'O₂', 'CO', 'H₂O', 'H₂S', 'He',
    'Ar'
  ];

  // Molar masses (g/mol) from RUST/src/detail.rs (MMI_DETAIL)
  final List<double> _molarMasses = [
    16.043,  // Methane
    28.0135, // Nitrogen
    44.01,   // Carbon dioxide
    30.07,   // Ethane
    44.097,  // Propane
    58.123,  // Isobutane
    58.123,  // n-Butane
    72.15,   // Isopentane
    72.15,   // n-Pentane
    86.177,  // Hexane
    100.204, // Heptane
    114.231, // Octane
    128.258, // Nonane
    142.285, // Decane
    2.0159,  // Hydrogen
    31.9988, // Oxygen
    28.01,   // Carbon monoxide
    18.0153, // Water
    34.082,  // Hydrogen sulfide
    4.0026,  // Helium
    39.948,  // Argon
  ];

  CompositionUnit _selectedUnit = CompositionUnit.molePercentage; // Default to Mole Percentage

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    final defaultComposition = [
      0.77824, 0.02, 0.06, 0.08, 0.03, 0.0015, 0.003, 0.0005, 0.00165,
      0.00215, 0.00088, 0.00024, 0.00015, 0.00009, 0.004, 0.005, 0.002,
      0.0001, 0.0025, 0.007, 0.001,
    ];
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].text = defaultComposition[i].toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllersFromFraction(defaultComposition);
    });
  }

  // Converts current controller values to mole fractions (for internal use and parent callback)
  List<double> _getCurrentCompositionAsFraction() {
    List<double> currentValues = _controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();

    switch (_selectedUnit) {
      case CompositionUnit.moleFraction:
        return currentValues;
      case CompositionUnit.molePercentage:
        return currentValues.map((v) => v / 100.0).toList();
      case CompositionUnit.massPercentage:
        // Convert mass percentage to mole fraction
        List<double> massFractions = currentValues.map((v) => v / 100.0).toList();
        double sumMoles = 0.0;
        List<double> moles = List.filled(21, 0.0);

        for (int i = 0; i < 21; i++) {
          if (_molarMasses[i] > 0) {
            moles[i] = massFractions[i] / _molarMasses[i];
            sumMoles += moles[i];
          }
        }

        if (sumMoles == 0) return List.filled(21, 0.0); // Avoid division by zero
        return moles.map((m) => m / sumMoles).toList();
    }
  }

  // Updates controllers and parent based on mole fractions
  void _updateControllersFromFraction(List<double> compositionFraction) {
    for (int i = 0; i < _controllers.length; i++) {
      double displayValue;
      switch (_selectedUnit) {
        case CompositionUnit.moleFraction:
          displayValue = compositionFraction[i];
          break;
        case CompositionUnit.molePercentage:
          displayValue = compositionFraction[i] * 100.0;
          break;
        case CompositionUnit.massPercentage:
          // Convert mole fraction to mass fraction for display
          double totalMoles = compositionFraction.fold(0.0, (sum, val) => sum + val);
          if (totalMoles == 0) {
            displayValue = 0.0;
          } else {
            double mole = compositionFraction[i];
            double mass = mole * _molarMasses[i];
            double totalMass = 0.0;
            for (int j = 0; j < 21; j++) {
              totalMass += compositionFraction[j] * _molarMasses[j];
            }
            displayValue = (totalMass == 0) ? 0.0 : (mass / totalMass) * 100.0;
          }
          break;
      }
      _controllers[i].text = displayValue.toStringAsFixed(5);
    }
    _updateParent(compositionFraction);
  }

  void _updateParent(List<double> compositionFraction) {
    widget.onChanged(compositionFraction);
    final sum = compositionFraction.fold(0.0, (prev, element) => prev + element);
    widget.onSumChanged(sum);
  }

  void _normalize() {
    final composition = _getCurrentCompositionAsFraction();
    final sum = composition.reduce((a, b) => a + b);
    if (sum == 0) return;

    final normalizedComposition = composition.map((c) => c / sum).toList();
    _updateControllersFromFraction(normalizedComposition);
  }

  void _copyComposition() {
    final composition = _getCurrentCompositionAsFraction();
    final String compositionText = composition.map((e) => e.toStringAsFixed(5)).join(', ');
    Clipboard.setData(ClipboardData(text: compositionText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Composition copied to clipboard!')),
    );
  }

  void _pasteFromExcel() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final lines = clipboardData.text!.trim().split('\n');
      List<double> pastedValues = [];
      for (int i = 0; i < _controllers.length; i++) {
        if (i < lines.length) {
          pastedValues.add(double.tryParse(lines[i].trim()) ?? 0.0);
        } else {
          pastedValues.add(0.0);
        }
      }

      // Convert pasted values to mole fractions before updating controllers
      List<double> pastedCompositionFraction;
      switch (_selectedUnit) {
        case CompositionUnit.moleFraction:
          pastedCompositionFraction = pastedValues;
          break;
        case CompositionUnit.molePercentage:
          pastedCompositionFraction = pastedValues.map((v) => v / 100.0).toList();
          break;
        case CompositionUnit.massPercentage:
          double sumMoles = 0.0;
          List<double> moles = List.filled(21, 0.0);
          for (int i = 0; i < 21; i++) {
            if (_molarMasses[i] > 0) {
              moles[i] = pastedValues[i] / _molarMasses[i];
              sumMoles += moles[i];
            }
          }
          if (sumMoles == 0) {
            pastedCompositionFraction = List.filled(21, 0.0);
          } else {
            pastedCompositionFraction = moles.map((m) => m / sumMoles).toList();
          }
          break;
      }
      _updateControllersFromFraction(pastedCompositionFraction);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pasted ${lines.length} values from clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty or contains no text.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              isSelected: CompositionUnit.values.map((unit) => _selectedUnit == unit).toList(),
              onPressed: (index) {
                setState(() {
                  _selectedUnit = CompositionUnit.values[index];
                  // Convert current values when toggling
                  final currentComposition = _getCurrentCompositionAsFraction();
                  _updateControllersFromFraction(currentComposition);
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Mole Fraction')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Mole Percentage')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Mass Percentage')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0, // gap between lines
          alignment: WrapAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _normalize,
              child: const Text('Normalize'),
            ),
            ElevatedButton(
              onPressed: _copyComposition,
              child: const Text('Copy All Composition'),
            ),
            ElevatedButton(
              onPressed: _pasteFromExcel,
              child: const Text('Paste from Excel'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _controllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${_componentNames[index]} (${_componentAbbreviations[index]})',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis, // Handle long names
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_molarMasses[index].toStringAsFixed(3)} g/mol',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis, // Handle long molar masses
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _controllers[index],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _updateParent(_getCurrentCompositionAsFraction());
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}