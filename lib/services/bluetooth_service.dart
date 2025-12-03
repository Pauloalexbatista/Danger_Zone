import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/player.dart';

class BluetoothService {
  // Unique Service UUID for Danger Zone game
  static const String SERVICE_UUID = "bf27730d-860a-4e09-889c-2d8b6a9e0fe7";

  // final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance; // No instance in 1.15.0+
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final _playersController = StreamController<List<Player>>.broadcast();

  Stream<List<Player>> get playersStream => _playersController.stream;

  // Map to track discovered players and their last RSSI
  final Map<String, Player> _discoveredPlayers = {};

  Future<void> init() async {
    await _requestPermissions();

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        _processScanResult(result);
      }
      _playersController.add(_discoveredPlayers.values.toList());
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  Future<void> startScanning() async {
    // Start scanning for devices with our specific service UUID
    // Note: filtering by UUID might not work on all Androids in background,
    // but works well in foreground.
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(SERVICE_UUID)],
        timeout: const Duration(seconds: 15), // Continuous scan in loops?
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print("Error starting scan: $e");
    }
  }

  Future<void> startAdvertising(String playerName, PlayerRole role) async {
    // Create Advertise Data
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: SERVICE_UUID,
      localName:
          "$playerName|${role.name}", // Encode name and role in localName
      includeDeviceName: false,
    );

    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: false,
    );

    await _blePeripheral.start(
      advertiseData: advertiseData,
      advertiseSettings: advertiseSettings,
    );
  }

  void _processScanResult(ScanResult result) {
    // We expect localName to be "Name|Role"
    String localName = result.advertisementData.localName;
    if (localName.isEmpty || !localName.contains('|')) return;

    List<String> parts = localName.split('|');
    if (parts.length < 2) return;

    String name = parts[0];
    String roleStr = parts[1];
    String id = result.device.remoteId.str; // remoteId.str is valid in 1.15.0?

    PlayerRole role = Player.parseRole(roleStr);

    if (_discoveredPlayers.containsKey(id)) {
      _discoveredPlayers[id]!.updateRssi(result.rssi);
    } else {
      _discoveredPlayers[id] = Player(
        id: id,
        name: name,
        role: role,
        rssi: result.rssi,
      );
    }
  }

  Future<void> stop() async {
    await FlutterBluePlus.stopScan();
    await _blePeripheral.stop();
  }
}
