
import 'package:flutter_test/flutter_test.dart';
import 'package:danger_zone/services/game_logic_service.dart';
import 'package:danger_zone/models/player.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('vibration');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'hasVibrator') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('GameLogicService', () {
    late GameLogicService gameLogicService;

    setUp(() {
      gameLogicService = GameLogicService();
    });

    test('calculateNewHealth returns same health for apanhador', () async {
      await gameLogicService.init();
      final newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.apanhador,
        nearbyPlayers: [],
        deltaTimeSeconds: 1.0,
      );
      expect(newHealth, 100.0);
    });

    test('calculateNewHealth applies damage for fugitivo when apanhador is very close', () async {
      await gameLogicService.init();
      final nearbyPlayers = [
        Player(
          id: '1',
          name: 'Apanhador',
          role: PlayerRole.apanhador,
          rssi: -50, // veryClose
        ),
      ];

      final newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: nearbyPlayers,
        deltaTimeSeconds: 1.0,
      );

      // DAMAGE_VERY_CLOSE = 50.0
      // 100.0 - (50.0 * 1.0) = 50.0
      expect(newHealth, 50.0);
    });

    test('calculateNewHealth does not apply damage if apanhador is far', () async {
      await gameLogicService.init();
      final nearbyPlayers = [
        Player(
          id: '1',
          name: 'Apanhador',
          role: PlayerRole.apanhador,
          rssi: -90, // far
        ),
      ];

      final newHealth = await gameLogicService.calculateNewHealth(
        currentHealth: 100.0,
        myRole: PlayerRole.fugitivo,
        nearbyPlayers: nearbyPlayers,
        deltaTimeSeconds: 1.0,
      );

      expect(newHealth, 100.0);
    });
  });
}
