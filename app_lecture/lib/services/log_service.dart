
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> logs = [];
  Function(String)? onNewLog;

  void add(String msg) {
    final log = "[${DateTime.now().toString().split(' ').last.substring(0, 8)}] $msg";
    logs.insert(0, log);
    if (logs.length > 100) logs.removeLast();
    if (onNewLog != null) onNewLog!(log);
    print("APP_LOG: $msg");
  }

  Future<String> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/debug_logs.txt');
      final content = logs.reversed.join('\n');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      return "Error: $e";
    }
  }
}
