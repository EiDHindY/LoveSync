import 'package:web/web.dart' as web;

void playSparkSound() {
  playNamedSound('heartbeat_pulse');
}

void playNamedSound(String soundName) {
  try {
    final audio = web.HTMLAudioElement();
    audio.src = 'sounds/$soundName.wav';
    audio.play();
  } catch (_) {}
}
