// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';

/// Versão web/preview: compartilha/copia texto e BAIXA a imagem do cartão.
class ShareHelper {
  ShareHelper._();

  static const String _signature = '\n\n— via app Frases & Status 💜';

  static Future<void> shareText(String text) async {
    await Share.share('$text$_signature');
  }

  /// Abre o WhatsApp Web/app com a frase escrita (versão web/preview).
  static Future<void> shareToWhatsApp(String text) async {
    final body = Uri.encodeComponent('$text$_signature');
    html.window.open('https://wa.me/?text=$body', '_blank');
  }

  static Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Captura o RepaintBoundary [key] e dispara o download do PNG no navegador.
  static Future<bool> shareBoundary(GlobalKey key,
      {required String text}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      final bytes = data.buffer.asUint8List();

      final blob = html.Blob(<Object>[bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = 'frase_${DateTime.now().millisecondsSinceEpoch}.png'
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sharePhraseImage(
      BuildContext context, Phrase phrase) async {
    await shareText(phrase.text);
    return true;
  }

  /// Web/preview: baixa o cartão como imagem (para depois subir no Instagram).
  static Future<bool> shareToInstagramStory(GlobalKey key,
      {required String text}) async {
    return shareBoundary(key, text: text);
  }
}
