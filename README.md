# AGA8 Gas Calculator

A cross-platform Flutter app for calculating natural gas properties using the AGA8 Detail Characterization method. Supports web, desktop, and mobile.

## Attribution
This project is based on the [usnistgov/AGA8](https://github.com/usnistgov/AGA8) RUST implementation, ported to WASM (WebAssembly) to ensure scientific and computational integrity. All unit conversions and data handling are performed in the frontend, outside of the core calculation engine, so the original algorithm remains unchanged.

## Features
- Input gas composition (21 components)
- Set pressure and temperature (bar(g)/bar(a), °C/K)
- Calculate Z-Factor, Gas Density, Molar Mass, and Speed of Sound
- Compare results at user conditions and standard conditions (1 atm, 15°C)
- Copy results to clipboard

## How to Use
1. **Enter Gas Composition:**
   - Input the mole fraction/percentage/mass percentage for each component.
   - Use the Normalize button to ensure the sum is 1 (or 100%).
   - You can copy/paste compositions for convenience.
2. **Set Pressure and Temperature:**
   - Enter the desired pressure and temperature values.
   - Select units (bar(g)/bar(a), °C/K).
3. **Calculate:**
   - Click the Calculate button.
   - Results for your input and standard conditions will be shown side by side.
4. **Copy Results:**
   - Use the Copy All Results button to copy the results to your clipboard.

## Notes
- Standard condition is 1 atm (1.01325 bar), 15°C (288.15 K).
- The app uses a WASM module for fast and accurate calculations in the browser.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart (comes with Flutter)
- Git

### Clone the Repository
```sh
git clone https://github.com/simyunyoung/aga8calc.git
cd aga8calc/aga8_calc_app
```

### Install Dependencies
```sh
flutter pub get
```

### Run on Web (Recommended for Desktop)
```sh
flutter run -d chrome
```

### Run on Desktop (macOS, Windows, Linux)
```sh
flutter run -d macos   # or -d windows, -d linux
```

### Run on Mobile
```sh
flutter run -d <device_id>
```

## Future Improvements (KIV)
- Migrate from dart:js_util to dart:js_interop for long-term compatibility.
- Expose AGA8 calculation as a REST API for integration with Excel, other apps, and automation workflows.
- Custom Component Support: Allow users to define and save custom gas components with their own properties.
- Interactive Charts: Visualize how properties (Z-Factor, density, etc.) change with pressure/temperature using interactive plots.
- Add Firebase Authentication: Use Google, email/password, or other providers. Only allow signed-in users to access the app or certain features.

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
MIT
