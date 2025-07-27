import 'package:flutter/material.dart';
import 'package:aga8_calc_app/aga8_service.dart';
import 'package:fl_chart/fl_chart.dart';

class CalculatorState with ChangeNotifier {
  AGA8Result? _result;
  AGA8Result? _standardResult;
  List<double> _composition = [
    88.53, // Methane (C1)
    0.10,  // Nitrogen (N2)
    3.29,  // CO2
    5.40,  // Ethane (C2)
    1.24,  // Propane (C3)
    0.17,  // i-Butane (iC4)
    0.13,  // n-Butane (nC4)
    0.05,  // i-Pentane (iC5)
    0.05,  // n-Pentane (nC5)
    0.98,  // Hexanes+ (C6+)
    // The rest (if 21 components required) can be set to 0.0
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
  ];
  double _pressure = 90.0;
  double _temperature = 30.0;
  bool _isPressureBarg = true;
  bool _isTempCelsius = true;
  double _compositionSum = 0.0;

  AGA8Result? get result => _result;
  AGA8Result? get standardResult => _standardResult;
  List<double> get composition => _composition;
  double get pressure => _pressure;
  double get temperature => _temperature;
  bool get isPressureBarg => _isPressureBarg;
  bool get isTempCelsius => _isTempCelsius;
  double get compositionSum => _compositionSum;

  void setComposition(List<double> composition) {
    _composition = composition;
    _compositionSum = composition.fold(0.0, (a, b) => a + b);
    notifyListeners();
  }

  void setPressure(double pressure) {
    _pressure = pressure;
    notifyListeners();
  }

  void setTemperature(double temperature) {
    _temperature = temperature;
    notifyListeners();
  }

  void setIsPressureBarg(bool isPressureBarg) {
    _isPressureBarg = isPressureBarg;
    notifyListeners();
  }

  void setIsTempCelsius(bool isTempCelsius) {
    _isTempCelsius = isTempCelsius;
    notifyListeners();
  }

  void calculate() {
    final pressureAbs = _isPressureBarg ? _pressure + 1.01325 : _pressure;
    final tempK = _isTempCelsius ? _temperature + 273.15 : _temperature;

    _result = AGA8Service.calculate(_composition, pressureAbs, tempK);
    _standardResult = AGA8Service.calculate(_composition, 1.01325, 288.15);
    notifyListeners();
  }

  // Method to generate data for Z-factor graph
  List<FlSpot> generateZGraphData({
    required List<double> composition,
    required double temperatureK,
    double minPressureBar = 1.0,
    double maxPressureBar = 200.0,
    int numberOfPoints = 50,
  }) {
    final List<FlSpot> spots = [];
    final double pressureStep = (maxPressureBar - minPressureBar) / (numberOfPoints - 1);

    for (int i = 0; i < numberOfPoints; i++) {
      final currentPressure = minPressureBar + (i * pressureStep);
      final result = AGA8Service.calculate(composition, currentPressure, temperatureK);
      if (result != null && result.error == null) {
        spots.add(FlSpot(currentPressure, result.zFactor));
      }
    }
    return spots;
  }
}
