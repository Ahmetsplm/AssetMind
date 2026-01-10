import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    // Regex to find .withOpacity(value) and replace with .withValues(alpha: value)
    // Handles simple decimals like 0.1, integers like 1, and variables like _opacity
    // But typically usages allow complex expressions.
    // The previous regex was `\.withOpacity\(([^)]+)\)` which assumes no nested parenthesis.
    // This is "good enough" for typical color usage.

    final newContent =
        content.replaceAllMapped(RegExp(r'\.withOpacity\(([^)]+)\)'), (match) {
      final value = match.group(1);
      return '.withValues(alpha: $value)';
    });

    if (content != newContent) {
      print('Updating ${file.path}');
      file.writeAsStringSync(newContent);
    }
  }
  print('Done.');
}
