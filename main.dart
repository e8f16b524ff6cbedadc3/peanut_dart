import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:logging/logging.dart';


Future<List<Element>> parse_loaction() async {
  var client = Client();
  Response resp = await client.get('http://www.62422.cn/search.asp?cataid=77');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  List<Element> links = document.querySelectorAll('a[href^=look]');
  return links;
}

Future<Map<String, List<String>>> parse_details(String path) async {
  String urlBase = 'http://www.62422.cn';
  var client = Client();
  Response resp = await client.get('$urlBase/$path');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  var title = document.querySelector('title').text.split('地区')[0].split('日')[1];
  //print(title);
  Iterable<String> data = document.body.text
      .split('点此查看会员收费标准与办理方式')[1].split('\n')[0]
      .split(new RegExp("(?=${title})"))
      .where((it) => it.startsWith(title))
      .map((it) => it.trim());
  return {title: data.toList()};
}


main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final Logger log = new Logger('main');
  log.info('fetching location list...');
  List<Element> links = await parse_loaction();
  log.info('fetch details data...');
  var seen = new Map();
  for (var link in links) {
    var data = await parse_details(link.attributes['href']);
    seen.addAll(data);
  }
  log.info('saving to result.json...');
  File resultFile = new File('_data/result.json');
  resultFile.writeAsString(json.encode(seen));
  log.info('done, shutting down...');
}
