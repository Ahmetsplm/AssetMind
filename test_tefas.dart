import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=MAC');
  final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'});
  print("Status: ${res.statusCode}");
  print("Body length: ${res.body.length}");
  print("Body preview: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}");
}
