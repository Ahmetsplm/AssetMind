import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse("https://corsproxy.io/?https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=GTL");
  final res = await http.get(url);
  print(res.statusCode);
  if (res.statusCode == 200) {
    final html = res.body;
    final idx = html.indexOf('Son Fiyat (TL)');
    print("idx: $idx");
  }
}
