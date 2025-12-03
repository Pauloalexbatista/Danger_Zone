import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/bluetooth_service.dart';
import '../services/game_logic_service.dart';
import '../widgets/health_bar.dart';
import '../widgets/proximity_radar.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final PlayerRole role;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.role,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final GameLogicService _gameLogic = GameLogicService();

  double _health = 100.0;
  List<Player> _nearbyPlayers = [];
  Timer? _gameLoopTimer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    // Start Game Loop IMMEDIATELY (Don't wait for Bluetooth)
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateGameState();
    });

    try {
      // Initialize Bluetooth
      await _bluetoothService.init();

      // Start Advertising & Scanning
      await _bluetoothService.startAdvertising(widget.playerName, widget.role);
      await _bluetoothService.startScanning();

      // Listen to players updates
      _bluetoothService.playersStream.listen((players) {
        if (mounted && !_isSimulationMode) {
          setState(() {
            _nearbyPlayers = players;
          });
        }
      });
    } catch (e) {
      print("Bluetooth Init Error: $e");
    }
  }

  int _tick = 0;

  void _updateGameState() async {
    _tick++;
    if (_isGameOver) return;

    try {
      // Keep simulated player alive
      if (_isSimulationMode && _nearbyPlayers.isNotEmpty) {
        _nearbyPlayers[0].lastSeen = DateTime.now();
      }

      // INLINED DEBUG LOGIC
      double damageTaken = 0.0;
      String debugReason = "None";

      // REAL DAMAGE LOGIC
      if (widget.role == PlayerRole.fugitivo) {
        for (var p in _nearbyPlayers) {
          if (p.role == PlayerRole.apanhador) {
            int age = DateTime.now().difference(p.lastSeen).inSeconds;
            if (age > 5) {
              debugReason = "Player expired (Age: $age)";
              continue;
            }

            if (p.proximity == ProximityLevel.veryClose) {
              damageTaken += 50.0; // Extreme damage for testing
              debugReason = "CRITICAL RADIATION!";
            } else if (p.proximity == ProximityLevel.close) {
              damageTaken += 2.0;
              debugReason = "Low Radiation";
            } else {
              debugReason = "Safe Distance (RSSI: ${p.rssi})";
            }
          }
        }
      } else {
        debugReason = "I am not Fugitivo (${widget.role})";
      }

      if (damageTaken > 0) {
        double newHealth = _health - (damageTaken * 0.1);
        if (mounted) {
          setState(() {
            _health = newHealth < 0 ? 0 : newHealth;
            _debugInfo = "Dmg: $damageTaken | $debugReason";
            if (_health <= 0) {
              _health = 0;
              _gameOver();
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _debugInfo = "No Dmg | $debugReason";
          });
        }
      }
    } catch (e, stack) {
      print("Error in game loop: $e");
      if (mounted) {
        setState(() {
          _debugInfo = "CRASH: $e";
        });
      }
    }
  }

  String _debugInfo = "";

  void _gameOver() {
    _isGameOver = true;
    _gameLoopTimer?.cancel();
    _bluetoothService.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("GAME OVER", style: TextStyle(color: Colors.white)),
        content: const Text("Foste apanhado pela radiação!",
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to Home
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _bluetoothService.stop();
    super.dispose();
  }

  ProximityLevel get _currentProximity {
    // If I am Apanhador, I don't have proximity danger (or maybe I detect Fugitivos?)
    // For MVP, Apanhador sees nothing on radar or maybe sees closest Fugitivo?
    // Let's make Apanhador see closest Fugitivo.

    PlayerRole targetRole = widget.role == PlayerRole.apanhador
        ? PlayerRole.fugitivo
        : PlayerRole.apanhador;

    int maxRssi = -100;

    for (var p in _nearbyPlayers) {
      if (p.role == targetRole) {
        if (p.rssi > maxRssi) maxRssi = p.rssi;
      }
    }

    if (maxRssi > -60) return ProximityLevel.veryClose;
    if (maxRssi > -80) return ProximityLevel.close;
    return ProximityLevel.far;
  }

  // Debug / Simulation State
  bool _isSimulationMode = false;
  double _simulatedRssi = -100;

  @override
  Widget build(BuildContext context) {
    // Damage Overlay (Red border)
    bool takingDamage = widget.role == PlayerRole.fugitivo &&
        _currentProximity != ProximityLevel.far &&
        _currentProximity != ProximityLevel.unknown;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // CHANGED FOR V6 VERIFICATION
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.role == PlayerRole.apanhador
                                      ? "🔴 APANHADOR"
                                      : "🏃 FUGITIVO",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    // Debug Button
                                    IconButton(
                                      icon: Icon(
                                          _isSimulationMode
                                              ? Icons.bug_report
                                              : Icons.bug_report_outlined,
                                          color: _isSimulationMode
                                              ? Colors.yellow
                                              : Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _isSimulationMode =
                                              !_isSimulationMode;
                                          if (_isSimulationMode) {
                                            // Add fake player for simulation
                                            _nearbyPlayers = [
                                              Player(
                                                  id: "sim-1",
                                                  name: "Simulado",
                                                  role: widget.role ==
                                                          PlayerRole.apanhador
                                                      ? PlayerRole.fugitivo
                                                      : PlayerRole.apanhador,
                                                  rssi: _simulatedRssi.toInt())
                                            ];
                                          } else {
                                            _nearbyPlayers = [];
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Health Bar
                            if (widget.role == PlayerRole.fugitivo) ...[
                              HealthBar(health: _health),
                              if (_isSimulationMode &&
                                  _nearbyPlayers.isNotEmpty)
                                Column(
                                  children: [
                                    Text(
                                      "HP: ${_health.toStringAsFixed(1)} | RSSI: ${_simulatedRssi.toInt()}",
                                      style: const TextStyle(
                                          color: Colors.yellow,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "P0: ${_nearbyPlayers[0].role.name} | ${_nearbyPlayers[0].rssi}dBm | Age: ${DateTime.now().difference(_nearbyPlayers[0].lastSeen).inMilliseconds}ms",
                                      style: const TextStyle(
                                          color: Colors.cyan, fontSize: 10),
                                    ),
                                    Text(
                                      "Prox: ${_nearbyPlayers[0].proximity.name}",
                                      style: const TextStyle(
                                          color: Colors.cyan, fontSize: 10),
                                    ),
                                    Text(
                                      _debugInfo,
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                            ],

                            const Spacer(),

                            // Radar
                            ProximityRadar(proximity: _currentProximity),

                            // Simulation Controls (Only in Debug Mode)
                            if (_isSimulationMode) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey[900],
                                child: Column(
                                  children: [
                                    const Text("MODO SIMULAÇÃO",
                                        style: TextStyle(color: Colors.yellow)),
                                    Slider(
                                      value: _simulatedRssi,
                                      min: -100,
                                      max: -40,
                                      divisions: 6,
                                      label: "${_simulatedRssi.toInt()} dBm",
                                      onChanged: (value) {
                                        setState(() {
                                          _simulatedRssi = value;
                                          // Update simulated player
                                          if (_nearbyPlayers.isNotEmpty) {
                                            _nearbyPlayers[0].updateRssi(
                                                _simulatedRssi.toInt());
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                        "Distância: ${_simulatedRssi > -60 ? 'MUITO PERTO' : _simulatedRssi > -80 ? 'PERTO' : 'LONGE'}",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Player List
                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[700]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "JOGADORES DETETADOS:",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _nearbyPlayers.length,
                                      itemBuilder: (context, index) {
                                        final p = _nearbyPlayers[index];
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            p.role == PlayerRole.apanhador
                                                ? Icons.warning
                                                : Icons.directions_run,
                                            color:
                                                p.role == PlayerRole.apanhador
                                                    ? Colors.red
                                                    : Colors.green,
                                          ),
                                          title: Text(p.name,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          trailing: Text(
                                            "${p.rssi} dBm",
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Damage Overlay (Flash Red)
          if (takingDamage)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.red.withOpacity(0.5), width: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
