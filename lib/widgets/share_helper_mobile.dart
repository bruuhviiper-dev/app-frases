import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import 'phrase_card.dart';

/// Utilitários para compartilhar frases como texto ou como imagem (status).
class ShareHelper {
  ShareHelper._();

  static const String _signature = '\n\n— via app Frases & Status 💜';

  /// Canal nativo para postar direto nos Stories do Instagram (Android).
  static const MethodChannel _channel =
      MethodChannel('frases_status/share');

  static Future<void> shareText(String text) async {
    await Share.share('$text$_signature');
  }

  /// Abre o WhatsApp já com a frase escrita, pronta para enviar a um contato
  /// ou postar no Status. Cai para a folha de compartilhamento padrão caso o
  /// WhatsApp não esteja instalado.
  static Future<void> shareToWhatsApp(String text) async {
    final body = Uri.encodeComponent('$text$_signature');
    final uri = Uri.parse('whatsapp://send?text=$body');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // ignora e cai no fallback abaixo
    }
    await Share.share('$text$_signature');
  }

  static Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Captura o RepaintBoundary [key] e compartilha como imagem PNG.
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
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/frase_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Salva o cartão [key] como PNG e tenta postar DIRETO nos Stories do
  /// Instagram via intent nativo (Android). Se o Instagram não estiver
  /// instalado ou o canal falhar, cai na folha de compartilhamento padrão
  /// (de onde o usuário ainda consegue escolher o Instagram).
  static Future<bool> shareToInstagramStory(GlobalKey key,
      {required String text}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      // 1) Tenta o caminho nativo "ADD_TO_STORY".
      try {
        final ok = await _channel.invokeMethod<bool>(
          'instagramStory',
          {'path': path},
        );
        if (ok == true) return true;
      } on PlatformException {
        // segue para o fallback
      } on MissingPluginException {
        // canal não registrado nesta plataforma; segue para o fallback
      }

      // 2) Fallback: folha de compartilhamento com a imagem.
      await Share.shareXFiles([XFile(path)], text: text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renderiza o cartão da frase fora da tela (via Overlay) e o compartilha
  /// como imagem PNG — ideal para o Status do WhatsApp.
  static Future<bool> sharePhraseImage(
      BuildContext context, Phrase phrase) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          // Pintado (para o toImage funcionar) mas invisível ao usuário.
          child: Opacity(
            opacity: 0.0,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 360,
                child: PhraseCard(phrase: phrase),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/frase_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        text: '${phrase.text}$_signature',
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      entry.remove();
    }
  }
}
