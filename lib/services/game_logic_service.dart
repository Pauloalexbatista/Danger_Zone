import 'dart:async';
import 'package:vibration/vibration.dart';
import '../models/player.dart';

class GameLogicService {
  // Damage constants (damage per second)
  static const double DAMAGE_VERY_CLOSE = 50.0; // EXTREME DAMAGE FOR TESTING
  static const double DAMAGE_CLOSE = 2.0;

  // Recovery constant
  static const double HEAL_RATE =
      1.0; // Passive heal if safe? Or only with Medic?
  // For MVP: No passive heal, only damage.

  Future<double> calculateNewHealth({
    required double currentHealth,
    required PlayerRole myRole,
    required List<Player> nearbyPlayers,
    required double deltaTimeSeconds, // Time since last update
  }) async {
    if (myRole == PlayerRole.apanhador) {
      return currentHealth; // Apanhador doesn't take damage in MVP
    }

    // I am a Fugitivo
    double damageTaken = 0.0;
    bool isVibrating = false;

    for (Player player in nearbyPlayers) {
      if (player.role == PlayerRole.apanhador) {
        // Check proximity
        // Note: We need to ensure we only count active players (lastSeen recently)
        if (DateTime.now().difference(player.lastSeen).inSeconds > 5) continue;

        if (player.proximity == ProximityLevel.veryClose) {
          damageTaken += DAMAGE_VERY_CLOSE;
          isVibrating = true;
        } else if (player.proximity == ProximityLevel.close) {
          damageTaken += DAMAGE_CLOSE;
        }
      }
    }

    if (damageTaken > 0) {
      // Apply damage
      double newHealth = currentHealth - (damageTaken * deltaTimeSeconds);

      // Haptic feedback
      if (isVibrating && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 100);
      }

      return newHealth < 0 ? 0 : newHealth;
    }

    return currentHealth;
  }
}
