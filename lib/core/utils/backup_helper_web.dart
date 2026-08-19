import 'dart:convert' show utf8;
import 'dart:html' as html;

void saveAndShareBackup(String backupString) {
  final bytes = utf8.encode(backupString);
  final blob = html.Blob([bytes], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "spendtrail_backup.stb")
    ..click();
  html.Url.revokeObjectUrl(url);
}
