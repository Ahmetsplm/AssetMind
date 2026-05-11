import 'package:http/http.dart' as http;

void main() async {
  final funds = ['GAV', 'GTL', 'GTZ', 'GL1'];
  for (var f in funds) {
    try {
      final res = await http.get(
        Uri.parse('https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=$f'),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)",
        }
      );
      print("$f status: ${res.statusCode}");
      if (res.statusCode == 200) {
        final html = res.body;
        final idx = html.indexOf('Son Fiyat (TL)');
        if (idx != -1) {
          final sub = html.substring(idx, idx + 300);
          final RegExp priceRegex = RegExp(r'>([\d,\.]+)<\/p>');
          final match = priceRegex.firstMatch(sub);
          if (match != null) {
            String priceStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
            print("$f price: $priceStr");
          }
        }
      }
    } catch (e) {
      print("$f error: $e");
    }
  }
}
