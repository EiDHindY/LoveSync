import 'package:web/web.dart' as web;

void playSparkSound() {
  try {
    final audio = web.HTMLAudioElement();
    audio.src = 'sounds/spark_match.wav';
    audio.play();
  } catch (_) {}
}
