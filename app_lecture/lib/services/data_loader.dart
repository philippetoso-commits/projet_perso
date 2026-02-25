
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/word.dart';
import 'asset_list.dart';

class DataLoader {
  static const String _boxName = 'words';

  Function(String)? onLog;

  void _log(String m) {
      print("DataLoader: $m");
      if (onLog != null) onLog!(m);
  }

  Future<void> initData() async {
    final box = await Hive.openBox<Word>(_boxName);



    // Force reload for development/update
    // TODO: Optimize this for production later
    await box.clear(); 
    _log("♻️ Database cleared. Reloading...");
    await _loadFromAssets(box);
  }



  Future<void> _loadFromAssets(Box<Word> box) async {
    _log("🚀 Using Static Asset List...");
    
    final jsonPaths = AssetList.jsonPaths;
    _log("🎯 Found ${jsonPaths.length} JSON data files.");

    if (jsonPaths.isEmpty) {
      _log("⚠️ WARNING: Static asset list is empty.");
      return;
    }

    int count = 0;
    for (final path in jsonPaths) {
      try {
        final content = await rootBundle.loadString(path);
        final data = json.decode(content);
        
        final word = Word.fromJson(data);
        await box.add(word);
        count++;
      } catch (e) {
        _log("❌ Error loading $path: $e");
      }
    }
    _log("🚀 Imported $count words successfully.");
  }
}
