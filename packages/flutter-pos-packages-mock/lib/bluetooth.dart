library bluetooth;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

enum BluetoothSignal {
  good(0),
  normal(0, 0),
  weak(0, 0);

  final int min;
  final int max;

  const BluetoothSignal(this.min, [this.max = 256]);

  static BluetoothSignal find(int value) => BluetoothSignal.weak;
}

enum PrinterStatus {
  good(0),
  unrecoverable(0),
  writeFailed(0),
  paperJams(0),
  paperNotFound(0),
  tooHot(0),
  lowBattery(0),
  uncovering(0),
  noResponse(0),
  printing(0),
  unknown(0);

  final int priority;

  const PrinterStatus(this.priority);
}

enum PrinterDensity {
  normal,
  tight;
}

class BluetoothOffException implements Exception {}

typedef BluetoothExceptionCode = fbp.FbpErrorCode;
typedef BluetoothException = fbp.FlutterBluePlusException;
typedef BluetoothExceptionFrom = fbp.ErrorPlatform;

class Bluetooth {
  static Bluetooth i = Bluetooth();
  Stream<List<BluetoothDevice>> startScan() => Stream.empty();
  Future<BluetoothDevice> connect(String address) => Future.value(BluetoothDevice());
  Future<List<BluetoothDevice>> pairedDevices() => Future.value([]);
  Future<void> stopScan() => Future.value();
}

class BluetoothDevice {
  final Stream<bool> connectionState = Stream.empty();
  final bool connected = false;
  final String name = '';
  final int mtu = 0;
  final String address = '';

  BluetoothDevice({fbp.BluetoothDevice? device});

  factory BluetoothDevice.demo() => BluetoothDevice();

  Future<void> connect() => Future.value();
  Future<void> disconnect() => Future.value();
  BluetoothService? getService(int id) => null;
  Stream<BluetoothSignal> createSignalStream({
    Duration interval = const Duration(minutes: 1),
  }) =>
      Stream.empty();
}

class BluetoothService {
  const BluetoothService(List<fbp.BluetoothCharacteristic> chars);

  bool hasCharacteristic(int id) => false;
  BluetoothCharacteristic? getCharacteristic(int id) => null;
}

class BluetoothCharacteristic {
  BluetoothCharacteristic(fbp.BluetoothCharacteristic char);

  Future<bool> watch() => Future.value(false);
  Stream<Uint8List> read() => Stream.empty();
  Future<void> write(Uint8List data) => Future.value();
}

abstract class PrinterManufactory {
  final int serviceUuid;
  final int writerChar;
  final int readerChar;
  final int widthMM;
  final int widthBits;

  const PrinterManufactory({
    this.serviceUuid = 0,
    this.writerChar = 0,
    this.readerChar = 0,
    this.widthMM = 0,
    this.widthBits = 0,
  });

  Uint8List prepare() => Uint8List(0);
  Uint8List toCommands(Uint8List image, {required PrinterDensity density}) => Uint8List(0);
  Future<PrinterStatus> getStatus({
    required fbp.BluetoothCharacteristic writer,
    required fbp.BluetoothCharacteristic reader,
  }) =>
      Future.value(PrinterStatus.unknown);

  static PrinterManufactory? tryGuess(String name) => null;
}

class Printer extends ChangeNotifier {
  final String address;
  final PrinterManufactory manufactory;
  final connected = false;
  final statusStream = Stream.value(PrinterStatus.unknown);

  BluetoothDevice? device;
  fbp.BluetoothCharacteristic? writer;
  fbp.BluetoothCharacteristic? reader;

  Printer({
    this.address = '',
    this.manufactory = const CatPrinter(),
    Printer? other,
  });

  Future<bool> connect() => Future.value(false);
  Future<void> disconnect() => Future.value();
  Stream<double> draw(
    Uint8List image, {
    PrinterDensity density = PrinterDensity.normal,
  }) =>
      Stream.empty();
}

class CatPrinter extends PrinterManufactory {
  const CatPrinter({int feedPaperByteSize = 0});
}

class XPrinter extends PrinterManufactory {
  const XPrinter({int widthMM = 0, int widthBits = 0})
      : super(widthMM: widthMM, widthBits: widthBits);
}

class YokoscanPrinter extends PrinterManufactory {
  const YokoscanPrinter({int widthMM = 0, int widthBits = 0})
      : super(widthMM: widthMM, widthBits: widthBits);
}

enum LogLevel { debug, info, warning, error }

class Logger {
  static LogLevel level = LogLevel.info;
  static void d(String message) {}
  static void i(String message) {}
  static void w(String message) {}
  static void e(String message) {}
}
