import 'dart:math';

enum PlayerRole {
  apanhador,
  fugitivo,
}

enum ProximityLevel {
  veryClose, // > -60 dBm
  close,     // > -80 dBm
  far,       // < -80 dBm
  unknown
}

class Player {
  final String id; // UUID or unique identifier
  final String name;
  final PlayerRole role;
  double health;
  int rssi;
  DateTime lastSeen;

  Player({
    required this.id,
    required this.name,
    required this.role,
    this.health = 100.0,
    this.rssi = -100,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  ProximityLevel get proximity {
    if (rssi > -60) return ProximityLevel.veryClose;
    if (rssi > -80) return ProximityLevel.close;
    return ProximityLevel.far;
  }

  void updateRssi(int newRssi) {
    rssi = newRssi;
    lastSeen = DateTime.now();
  }

  // Helper to parse role from advertised name or service UUID if needed
  static PlayerRole parseRole(String roleString) {
    return roleString.toLowerCase() == 'apanhador' 
        ? PlayerRole.apanhador 
        : PlayerRole.fugitivo;
  }
}
