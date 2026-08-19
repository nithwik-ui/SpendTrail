import 'dart:convert' show utf8;
import 'dart:html' as html;

void saveAndShareCsv(String csvString) {
  final bytes = utf8.encode(csvString);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "spendtrail_export.csv")
    ..click();
  html.Url.revokeObjectUrl(url);
}
