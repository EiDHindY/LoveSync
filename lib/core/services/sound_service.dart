import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:love_app/core/services/sound_player/sound_player.dart' as fallback;

class SoundOption {
  final String id;
  final String name;
  final String description;
  final String icon;

  const SoundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<SoundOption> kSparkSoundOptions = [
  SoundOption(
    id: 'romantic_harp',
    name: 'Soft Romantic Harp & Chimes',
    description: 'Gentle, warm, and dreamy ascending chord with an acoustic tail',
    icon: '🎵',
  ),
  SoundOption(
    id: 'heartbeat_pulse',
    name: 'Intimate Heartbeat & Warm Tone',
    description: 'Tender double heartbeat pulse followed by a velvety soft chime',
    icon: '💓',
  ),
  SoundOption(
    id: 'crystal_bells',
    name: 'Crystal Glass Bells',
    description: 'Crisp, joyful, and playful sparkling glass chime',
    icon: '✨',
  ),
  SoundOption(
    id: 'velvet_rhodes',
    name: 'Velvet Rhodes Swell',
    description: 'Smooth, lush, and modern vintage electric piano romance',
    icon: '🎹',
  ),
  SoundOption(
    id: 'classic_spark',
    name: 'Classic Spark',
    description: 'Original double-blind chime alert',
    icon: '🔥',
  ),
];

const List<SoundOption> kCancelSoundOptions = [
  SoundOption(
    id: 'sunset_marimba',
    name: 'Tender Sunset Marimba',
    description: 'Warm, grounding wooden marimba descending gently with natural acoustic resonance',
    icon: '🪵',
  ),
  SoundOption(
    id: 'cloud_breath',
    name: 'Cloud Breath & Soft Sigh',
    description: 'Gentle, airy ambient chord resolving softly into quiet reassurance',
    icon: '☁️',
  ),
  SoundOption(
    id: 'gentle_rain',
    name: 'Gentle Raindrop Ripple',
    description: 'Soft organic water drops flowing into a warm, calming singing bowl sustain',
    icon: '💧',
  ),
  SoundOption(
    id: 'acoustic_sigh',
    name: 'Acoustic Guitar Lullaby',
    description: 'Delicate fingerpicked nylon strings with sweet, intimate warmth',
    icon: '🎸',
  ),
  SoundOption(
    id: 'velvet_ember',
    name: 'Velvet Ember Glow',
    description: 'Vintage Rhodes electric piano with warm tremolo and peaceful release',
    icon: '🕯️',
  ),
];

const List<SoundOption> kDateRequestSoundOptions = [
  SoundOption(
    id: 'moonlight_vibe',
    name: 'Moonlight Vibraphone & Flute',
    description: 'Silky smooth jazz vibraphone chord with a warm, breathy flute swell',
    icon: '🌙',
  ),
  SoundOption(
    id: 'romantic_harp',
    name: 'Soft Romantic Harp & Chimes',
    description: 'Gentle ascending acoustic harp chord with dreamy crystalline tail',
    icon: '🎵',
  ),
  SoundOption(
    id: 'paris_romance',
    name: 'French Café Accordion & Bell',
    description: 'Romantic Parisian accordion swell with sweet vintage bell chime',
    icon: '🪗',
  ),
  SoundOption(
    id: 'rosewood_kalimba',
    name: 'Rosewood Kalimba & Music Box',
    description: 'Organic wooden thumb-piano melody with twinkling music-box resonance',
    icon: '✨',
  ),
  SoundOption(
    id: 'pizzicato_waltz',
    name: 'Pizzicato Waltz & Guitar',
    description: 'Playful plucked violin pizzicato resolving into a tender acoustic guitar strum',
    icon: '🎻',
  ),
];

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _player;

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  Future<void> playSound(String soundId) async {
    try {
      if (kIsWeb) {
        // Use web fallback or audioplayer
        fallback.playNamedSound(soundId);
        return;
      }
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$soundId.wav'));
    } catch (e) {
      debugPrint('Error playing sound $soundId via audioplayers: $e');
      try {
        fallback.playNamedSound(soundId);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
