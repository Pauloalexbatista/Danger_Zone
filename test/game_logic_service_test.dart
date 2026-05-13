import 'package:flutter_test/flutter_test.dart';
import 'package:danger_zone/models/player.dart';
import 'package:danger_zone/services/game_logic_service.dart';

void main() {
  group('GameLogicService Tests', () {
    late GameLogicService gameLogicService;

    setUp(() {
      gameLogicService = GameLogicService();
    });

    test('Apanhador doesn\'t take damage', () async {
      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.apanhador,
        nearbyPlayers: [
          Player(id: '1', name: 'Fugi', role: PlayerRole.fugitivo, rssi: -40),
        ],
        deltaTimeSeconds: 1.0,
      );

      expect(newHealth, 100.0);
    });

    test('Fugitivo takes very close damage from Apanhador', () async {
      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [
          Player(id: '1', name: 'Vilao', role: PlayerRole.apanhador, rssi: -40), // -40 is veryClose
        ],
        deltaTimeSeconds: 1.0,
      );

      // 100 - (50.0 * 1.0) = 50.0
      expect(newHealth, 50.0);
    });

    test('Fugitivo takes close damage from Apanhador', () async {
      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [
          Player(id: '1', name: 'Vilao', role: PlayerRole.apanhador, rssi: -70), // -70 is close
        ],
        deltaTimeSeconds: 1.0,
      );

      // 100 - (2.0 * 1.0) = 98.0
      expect(newHealth, 98.0);
    });

    test('Fugitivo takes no damage if Apanhador is far', () async {
      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [
          Player(id: '1', name: 'Vilao', role: PlayerRole.apanhador, rssi: -90), // -90 is far
        ],
        deltaTimeSeconds: 1.0,
      );

      expect(newHealth, 100.0);
    });

    test('Fugitivo takes no damage from other Fugitivos', () async {
       double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [
          Player(id: '1', name: 'Amigo', role: PlayerRole.fugitivo, rssi: -40),
        ],
        deltaTimeSeconds: 1.0,
      );

      expect(newHealth, 100.0);
    });

    test('Health does not drop below 0', () async {
      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 10.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [
          Player(id: '1', name: 'Vilao', role: PlayerRole.apanhador, rssi: -40), // -40 is veryClose
        ],
        deltaTimeSeconds: 1.0,
      );

      // 10 - (50.0 * 1.0) = -40 -> expects 0
      expect(newHealth, 0.0);
    });

    test('Ignores stale Apanhador data', () async {
      Player stalePlayer = Player(id: '1', name: 'Vilao', role: PlayerRole.apanhador, rssi: -40);
      // Simulate last seen 10 seconds ago
      stalePlayer.lastSeen = DateTime.now().subtract(const Duration(seconds: 10));

      double newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: [stalePlayer],
        deltaTimeSeconds: 1.0,
      );

      expect(newHealth, 100.0);
    });
  });
}
