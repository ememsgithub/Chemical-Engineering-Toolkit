import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const EngineeringToolkitApp());
}

class EngineeringToolkitApp extends StatelessWidget {
  const EngineeringToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eng Toolkit',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CalculatorListScreen(),
    );
  }
}

// --- Data Models ---
class CalcInput {
  final String label;
  final String unit;
  CalcInput(this.label, this.unit);
}

class CalcResult {
  final String value;
  final String unit;
  final String comment;
  CalcResult(this.value, this.unit, this.comment);
}

class CalculatorConfig {
  final String title;
  final List<CalcInput> inputs;
  final CalcResult Function(List<double> values) compute;

  CalculatorConfig(this.title, this.inputs, this.compute);
}

// --- The Expanded Calculators Configuration ---
final List<CalculatorConfig> calculators = [
  CalculatorConfig(
    "Reynolds Number",
    [
      CalcInput("Density", "kg/m³"),
      CalcInput("Velocity", "m/s"),
      CalcInput("Diameter", "m"), 
      CalcInput("Viscosity", "Pa·s"),
    ],
    (v) {
      double re = (v[0] * v[1] * v[2]) / v[3];
      String comment = re < 2100 ? "Laminar flow" : (re < 4000 ? "Transition flow" : "Turbulent flow");
      return CalcResult(re.toStringAsFixed(2), "dimensionless", comment);
    },
  ),
  CalculatorConfig(
    "Bernoulli Equation (P2)",
    [
      CalcInput("P1", "Pa"), CalcInput("v1", "m/s"), CalcInput("z1", "m"),
      CalcInput("v2", "m/s"), CalcInput("z2", "m"), CalcInput("Density", "kg/m³"),
    ],
    (v) {
      double p2 = v[0] + 0.5 * v[5] * (pow(v[1], 2) - pow(v[3], 2)) + v[5] * 9.81 * (v[2] - v[4]);
      return CalcResult(p2.toStringAsFixed(2), "Pa", "Assumes incompressible, ideal fluid.");
    },
  ),
  CalculatorConfig(
    "Antoine Equation",
    [CalcInput("A", "-"), CalcInput("B", "-"), CalcInput("C", "-"), CalcInput("Temp", "°C")],
    (v) {
      double p = pow(10, v[0] - (v[1] / (v[3] + v[2]))).toDouble();
      return CalcResult(p.toStringAsFixed(4), "mmHg", "Ensure constants match Celsius/mmHg.");
    },
  ),
  CalculatorConfig(
    "Pump Power",
    [CalcInput("Flow Rate", "m³/s"), CalcInput("Head", "m"), CalcInput("Density", "kg/m³"), CalcInput("Efficiency", "0-1")],
    (v) {
      double pwr = (v[0] * v[2] * 9.81 * v[1]) / v[3];
      return CalcResult((pwr / 1000).toStringAsFixed(2), "kW", "Shaft power required.");
    },
  ),
  CalculatorConfig(
    "Distillation (Fenske)",
    [CalcInput("Rel. Volatility (α)", "-"), CalcInput("xD (Light Key)", "0-1"), CalcInput("xB (Light Key)", "0-1")],
    (v) {
      double n = log((v[1] / (1 - v[1])) * ((1 - v[2]) / v[2])) / log(v[0]);
      return CalcResult(n.toStringAsFixed(2), "stages", "Minimum theoretical stages (total reflux).");
    },
  ),
  CalculatorConfig(
    "Heat Exchanger LMTD",
    [CalcInput("T_hot,in", "°C"), CalcInput("T_hot,out", "°C"), CalcInput("T_cold,in", "°C"), CalcInput("T_cold,out", "°C")],
    (v) {
      double dt1 = v[0] - v[3]; double dt2 = v[1] - v[2];
      double lmtd = (dt1 == dt2) ? dt1 : (dt1 - dt2) / log(dt1 / dt2);
      return CalcResult(lmtd.toStringAsFixed(2), "°C", "Assumes counter-current flow.");
    },
  ),
  CalculatorConfig(
    "Plug Flow Reactor",
    [CalcInput("Flow Fa0", "mol/s"), CalcInput("Conc Ca0", "mol/m³"), CalcInput("Conversion X", "0-1"), CalcInput("Rate k", "1/s")],
    (v) {
      double vol = (v[0] / (v[3] * v[1])) * -log(1 - v[2]);
      return CalcResult(vol.toStringAsFixed(4), "m³", "Constant density, 1st order reaction.");
    },
  ),
  CalculatorConfig(
    "Mass Transfer (Fick's)",
    [CalcInput("Diffusivity", "m²/s"), CalcInput("Area", "m²"), CalcInput("ΔC", "mol/m³"), CalcInput("Δx", "m")],
    (v) {
      double flux = v[0] * (v[2] / v[3]) * v[1];
      return CalcResult(flux.abs().toStringAsFixed(6), "mol/s", "Steady-state linear diffusion.");
    },
  ),
  CalculatorConfig(
    "Psychrometrics (RH)",
    [CalcInput("P_water", "Pa"), CalcInput("P_sat", "Pa")],
    (v) {
      double rh = min((v[0] / v[1]) * 100, 100);
      return CalcResult(rh.toStringAsFixed(2), "%", "Relative humidity (capped at 100%).");
    },
  ),
  CalculatorConfig(
    "Orifice Flow",
    [CalcInput("Discharge Cd", "-"), CalcInput("Area", "m²"), CalcInput("Density", "kg/m³"), CalcInput("ΔP", "Pa")],
    (v) {
      double q = v[0] * v[1] * sqrt((2 * v[3]) / v[2]);
      return CalcResult(q.toStringAsFixed(4), "m³/s", "Incompressible fluid orifice equation.");
    },
  ),
  CalculatorConfig(
    "Power Number",
    [CalcInput("Power", "W"), CalcInput("Density", "kg/m³"), CalcInput("Speed N", "rev/s"), CalcInput("Diameter D", "m")],
    (v) {
      double np = v[0] / (v[1] * pow(v[2], 3) * pow(v[3], 5));
      return CalcResult(np.toStringAsFixed(2), "dimensionless", "Varies based on impeller type.");
    },
  ),
  // --- EXPANDED 10-COMPONENT VLE ---
  CalculatorConfig(
    "10-Comp VLE (Raoult's)",
    [
      // Dynamically generate 20 input fields
      for (int i = 1; i <= 10; i++) ...[
        CalcInput("x$i (Mole Fraction)", "-"),
        CalcInput("P_sat$i", "Pa"),
      ]
    ], 
    (v) {
      double pTotal = 0;
      double xTotal = 0;
      for (int i = 0; i < 10; i++) {
        xTotal += v[i * 2]; // Even indices are mole fractions
        pTotal += v[i * 2] * v[(i * 2) + 1]; // Fraction * P_sat
      }
      if ((xTotal - 1.0).abs() > 0.01) {
        return CalcResult("Error", "-", "Mole fractions must sum to 1.0. Current sum: ${xTotal.toStringAsFixed(3)}");
      }
      return CalcResult(pTotal.toStringAsFixed(2), "Pa", "Total Bubble Point Pressure.");
    },
  ),
  CalculatorConfig(
    "Pipe Friction",
    [CalcInput("Friction f", "-"), CalcInput("Length", "m"), CalcInput("Diameter", "m"), CalcInput("Velocity", "m/s"), CalcInput("Density", "kg/m³")],
    (v) {
      double dp = v[0] * (v[1] / v[2]) * (v[4] * pow(v[3], 2) / 2);
      return CalcResult(dp.toStringAsFixed(2), "Pa", "Darcy-Weisbach pressure loss.");
    },
  ),
  CalculatorConfig(
    "Compressor Power",
    [CalcInput("P1", "Pa"), CalcInput("P2", "Pa"), CalcInput("Flow Rate", "m³/s"), CalcInput("Gamma (γ)", "-")],
    (v) {
      double pwr = v[0] * v[2] * (v[3] / (v[3] - 1)) * (pow((v[1] / v[0]), ((v[3] - 1) / v[3])) - 1);
      return CalcResult((pwr / 1000).toStringAsFixed(2), "kW", "Ideal isentropic power.");
    },
  ),
  // --- EXPANDED UNIT CONVERTERS ---
  CalculatorConfig(
    "Unit Converter: Temperature",
    [CalcInput("Base Temperature", "°C")],
    (v) {
      double k = v[0] + 273.15;
      double f = (v[0] * 9 / 5) + 32;
      return CalcResult(k.toStringAsFixed(2), "K", "Also equals: ${f.toStringAsFixed(2)} °F");
    },
  ),
  CalculatorConfig(
    "Unit Converter: Pressure",
    [CalcInput("Base Pressure", "psi")],
    (v) {
      double pa = v[0] * 6894.76;
      double bar = v[0] * 0.0689476;
      return CalcResult(pa.toStringAsFixed(2), "Pa", "Also equals: ${bar.toStringAsFixed(4)} bar");
    },
  ),
  CalculatorConfig(
    "Unit Converter: Length",
    [CalcInput("Base Length", "m")],
    (v) {
      double ft = v[0] * 3.28084;
      double inch = v[0] * 39.3701;
      return CalcResult(ft.toStringAsFixed(2), "ft", "Also equals: ${inch.toStringAsFixed(2)} inches");
    },
  ),
];

// --- UI Screens ---

class CalculatorListScreen extends StatelessWidget {
  const CalculatorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engineering Toolkit')),
      body: ListView.builder(
        itemCount: calculators.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(calculators[index].title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalculatorScreen(config: calculators[index])),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final CalculatorConfig config;
  const CalculatorScreen({super.key, required this.config});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late List<TextEditingController> _controllers;
  CalcResult? _result;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.config.inputs.length, (i) => TextEditingController());
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    super.dispose();
  }

  void _calculate() {
    try {
      List<double> values = _controllers.map((c) => double.parse(c.text)).toList();
      setState(() {
        _result = widget.config.compute(values);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid numbers in all fields")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.config.inputs.length,
                itemBuilder: (context, index) {
                  final input = widget.config.inputs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextField(
                      controller: _controllers[index],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: input.label,
                        suffixText: input.unit,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('CALCULATE', style: TextStyle(fontSize: 16)),
            ),
            if (_result != null) ...[
              const Divider(height: 40, thickness: 2),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.value == "Error" ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.value == "Error" ? Colors.red.shade200 : Colors.blue.shade200
                  )
                ),
                child: Column(
                  children: [
                    Text(
                      _result!.value == "Error" 
                          ? "Error" 
                          : "Result: ${_result!.value} ${_result!.unit}", 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: _result!.value == "Error" ? Colors.redAccent : Colors.blueAccent
                      )
                    ),
                    const SizedBox(height: 8),
                    Text(_result!.comment, 
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
