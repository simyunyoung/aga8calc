import init, { calculate_aga8 } from './pkg/aga8.js';

window.aga8Bridge = {
  initWasm: async function() {
    console.log("Attempting to initialize WASM module via bridge...");
    await init();
    console.log("WASM module initialized via bridge.");
  },
  calculate: function(composition, pressure, temperature) {
    console.log("Calling calculate_aga8 via bridge...");
    try {
      const result = calculate_aga8(composition, pressure, temperature);
      console.log("Result from WASM via bridge:", result);
      
      // Check if the result is an instance of AGA8Result
      if (result && typeof result === 'object') {
        // Log all properties of the result object
        console.log("Result properties:");
        for (const prop in result) {
          console.log(`${prop}: ${result[prop]}`);
        }
        
        // Create a plain JavaScript object with the properties
        // Map from camelCase to snake_case
        const plainResult = {
          z_factor: result.zFactor,
          gas_density_kg_m3: result.gasDensity,
          molar_mass_g_mol: result.molarMass,
          speed_of_sound_m_s: result.speedOfSound
        };
        
        console.log("Converted result:", plainResult);
        return plainResult;
      } else {
        console.error("Result is not an object:", result);
        return {
          z_factor: 0,
          gas_density_kg_m3: 0,
          molar_mass_g_mol: 0,
          speed_of_sound_m_s: 0
        };
      }
    } catch (e) {
      console.error("Error calling WASM via bridge:", e);
      throw e; // Re-throw to propagate the error
    }
  }
};

// Initialize WASM when the bridge script loads
window.aga8Bridge.initWasm();