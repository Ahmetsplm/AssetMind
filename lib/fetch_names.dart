import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_print, empty_catches

void main() async {
  final file = File('lib/services/global_whitelist.dart');
  final content = await file.readAsString();
  final regex = RegExp(r'"([^"]+)"');
  final matches = regex.allMatches(content);
  final symbols = matches.map((m) => m.group(1)!).toList();

  print('Fetching names for ${symbols.length} symbols...');
  
  final Map<String, String> namesMap = {};
  
  final client = http.Client();
  
  const int chunkSize = 50;
  for (int i = 0; i < symbols.length; i += chunkSize) {
    final chunk = symbols.skip(i).take(chunkSize).toList();
    
    final futures = chunk.map((sym) async {
      try {
        final url = Uri.parse('https://query2.finance.yahoo.com/v1/finance/search?q=$sym');
        final response = await client.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['quotes'] != null && data['quotes'].isNotEmpty) {
            final firstQuote = data['quotes'][0];
            final name = firstQuote['shortname'] ?? firstQuote['longname'] ?? sym;
            return MapEntry(sym, name as String);
          }
        }
      } catch (e) {}
      return MapEntry(sym, sym);
    });
    
    final results = await Future.wait(futures);
    for (var r in results) {
      namesMap[r.key] = r.value;
    }
    print('Fetched ${i + chunk.length}/${symbols.length}');
  }
  
  client.close();
  
  final buffer = StringBuffer();
  buffer.writeln('const Map<String, String> globalNames = {');
  for (var entry in namesMap.entries) {
    var val = entry.value.replaceAll("'", "\\'");
    buffer.writeln("  '${entry.key}': '$val',");
  }
  buffer.writeln('};');
  
  final outFile = File('lib/services/global_names.dart');
  await outFile.writeAsString(buffer.toString());
  print('Done!');
}
