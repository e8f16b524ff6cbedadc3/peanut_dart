import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:logging/logging.dart';

Future<List<Element>> parse_loaction(Client client) async {
  Response resp = await client.get('http://www.62422.cn/search.asp?cataid=77');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  List<Element> links = document.querySelectorAll('a[href^=look]');
  return links;
}

Future<Map<String, List<String>>> parse_details(
    Client client, String path) async {
  String urlBase = 'http://www.62422.cn';
  Response resp = await client.get('$urlBase/$path');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  var title = document.querySelector('title').text.split('地区')[0].split('日')[1];
  //print(title);
  Iterable<String> data = document.body.text
      .split('点此查看会员收费标准与办理方式')[1]
      .split('\n')[0]
      .split(new RegExp("(?=${title})"))
      .where((it) => it.startsWith(title))
      .map((it) => it.trim());
  return {title: data.toList()};
}

Future<Map<String, List<String>>> fetchData() async {
  final Logger log = new Logger('fetchData');
  final Client client = Client();

  log.info('fetching location list...');
  List<Element> links = await parse_loaction(client);

  log.info('fetch details data...');
  Map<String, List<String>> seen = new Map();
  for (Element link in links) {
    var data = await parse_details(client, link.attributes['href']);
    seen.addAll(data);
  }
  return seen;
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  final Logger log = new Logger('main');

  log.info('fetching...');
  Map<String, List<String>> seen = await fetchData();

  log.info('saving to result.json...');
  File resultFile = new File('_data/result.json');
  resultFile.writeAsString(json.encode(seen));

  log.info('done, shutting down...');
}
