// Web implementation using dart:html
import 'dart:html' as html;

String? getSessionItem(String key) {
  return html.window.sessionStorage[key];
}

void setSessionItem(String key, String value) {
  html.window.sessionStorage[key] = value;
}

void removeSessionItem(String key) {
  html.window.sessionStorage.remove(key);
}