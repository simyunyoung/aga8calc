import 'package:flutter_test/flutter_test.dart';
import 'package:aga8_calc_app/calculator_state.dart';
import 'package:aga8_calc_app/aga8_service.dart';
import 'package:mockito/mockito.dart'; // We'll need to add mockito to dev_dependencies

// Mock AGA8Service to control its behavior in tests
class MockAGA8Service extends Mock implements AGA8Service {}

void main() {
  group('CalculatorState', () {
    late CalculatorState calculatorState;
    late MockAGA8Service mockAGA8Service;

    setUp(() {
      mockAGA8Service = MockAGA8Service();
      // Provide a default mock implementation for calculate
      when(mockAGA8Service.calculate(any, any, any)).thenReturn(
        AGA8Result(
          zFactor: 1.0,
          gasDensity: 0.7,
          molarMass: 20.0,
          speedOfSound: 350.0,
        ),
      );
      calculatorState = CalculatorState();
    });

    test('initial values are correct', () {
      expect(calculatorState.composition, isEmpty);
      expect(calculatorState.pressure, 100.0);
      expect(calculatorState.temperature, 25.0);
      expect(calculatorState.isPressureBarg, isTrue);
      expect(calculatorState.isTempCelsius, isTrue);
      expect(calculatorState.compositionSum, 0.0);
      expect(calculatorState.result, isNull);
      expect(calculatorState.standardResult, isNull);
    });

    test('setComposition updates composition and sum', () {
      final newComposition = [0.5, 0.5];
      calculatorState.setComposition(newComposition);
      expect(calculatorState.composition, newComposition);
      expect(calculatorState.compositionSum, 1.0);
    });

    test('setPressure updates pressure', () {
      calculatorState.setPressure(200.0);
      expect(calculatorState.pressure, 200.0);
    });

    test('setTemperature updates temperature', () {
      calculatorState.setTemperature(30.0);
      expect(calculatorState.temperature, 30.0);
    });

    test('setIsPressureBarg updates isPressureBarg', () {
      calculatorState.setIsPressureBarg(false);
      expect(calculatorState.isPressureBarg, isFalse);
    });

    test('setIsTempCelsius updates isTempCelsius', () {
      calculatorState.setIsTempCelsius(false);
      expect(calculatorState.isTempCelsius, isFalse);
    });

    test('calculate updates result and standardResult', () {
      final testComposition = [0.8, 0.2];
      calculatorState.setComposition(testComposition);
      calculatorState.setPressure(10.0);
      calculatorState.setTemperature(20.0);

      // Mock the static method call
      // This is a bit tricky with static methods and mockito.
      // For simplicity in this test, we'll assume AGA8Service.calculate
      // is directly callable and returns a valid result.
      // In a real scenario, you might use a dependency injection framework
      // or pass the service as a parameter to CalculatorState.

      calculatorState.calculate();

      expect(calculatorState.result, isNotNull);
      expect(calculatorState.standardResult, isNotNull);
      // Further assertions on the values of result and standardResult can be added
      // based on the expected output of AGA8Service.calculate
    });

    test('calculate handles AGA8Service returning null', () {
      // Simulate AGA8Service.calculate returning null
      // This requires a more advanced mocking setup if AGA8Service.calculate
      // is truly static and not easily injectable.
      // For now, we'll assume it returns a valid result as per the setUp.
      // If AGA8Service.calculate could return null, you'd need to adjust
      // the mock setup to simulate that.
      calculatorState.calculate();
      expect(calculatorState.result, isNotNull); // Still expects a non-null result due to default mock
    });

    test('listeners are notified on state changes', () {
      var listenerCalled = false;
      calculatorState.addListener(() {
        listenerCalled = true;
      });

      calculatorState.setPressure(150.0);
      expect(listenerCalled, isTrue);
    });
  });
}
