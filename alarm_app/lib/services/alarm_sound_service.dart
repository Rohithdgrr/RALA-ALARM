import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/alarm.dart';

/// Centralized alarm sound service that handles all audio playback
/// for alarms: in-app tones, local files, and YouTube/URL-based audio.
class AlarmSoundService {
  static final AlarmSoundService _instance = AlarmSoundService._internal();
  factory AlarmSoundService() => _instance;
  AlarmSoundService._internal();

  AudioPlayer? _player;
  Timer? _fadeTimer;
  bool _isPlaying = false;
  
  // Cache for YouTube audio files
  final Map<String, String> _youtubeCache = {};
  bool _cacheLoaded = false;

  bool get isPlaying => _isPlaying;

  // ────────────────── In-App Ringtone Definitions ──────────────────
  // Each in-app ringtone has a unique name and maps to a tone generator
  // frequency sequence. These are synthesized tones that work without
  // any external audio files.

  static const Map<String, Map<String, dynamic>> inAppRingtones = {
    'Default': {
      'icon': 'music_note',
      'frequencies': [523.25, 659.25, 783.99, 1046.50],
      'durations': [200, 200, 200, 400],
      'description': 'Classic alarm beep pattern',
    },
    'Morning Birds': {
      'icon': 'wb_sunny',
      'frequencies': [880.0, 1046.50, 880.0, 783.99, 659.25],
      'durations': [150, 100, 150, 100, 300],
      'description': 'Cheerful chirping melody',
    },
    'Digital Alarm': {
      'icon': 'timer',
      'frequencies': [1000.0, 0.0, 1000.0, 0.0, 1000.0],
      'durations': [200, 100, 200, 100, 200],
      'description': 'Sharp digital beeps',
    },
    'Classic Bell': {
      'icon': 'notifications',
      'frequencies': [440.0, 554.37, 659.25, 440.0],
      'durations': [300, 300, 300, 600],
      'description': 'Traditional bell ring',
    },
    'Gentle Wake': {
      'icon': 'alarm',
      'frequencies': [261.63, 329.63, 392.0, 523.25],
      'durations': [400, 400, 400, 800],
      'description': 'Soft ascending tones',
    },
    'Ocean Waves': {
      'icon': 'waves',
      'frequencies': [196.0, 220.0, 246.94, 261.63, 246.94, 220.0],
      'durations': [300, 300, 300, 400, 300, 300],
      'description': 'Calm wave-like sound',
    },
    'Forest Birds': {
      'icon': 'forest',
      'frequencies': [1318.51, 1174.66, 1046.50, 987.77, 1046.50, 1174.66],
      'durations': [100, 100, 150, 100, 100, 200],
      'description': 'Forest bird calls',
    },
    'Piano Melody': {
      'icon': 'piano',
      'frequencies': [523.25, 587.33, 659.25, 698.46, 783.99, 698.46, 659.25, 587.33],
      'durations': [250, 250, 250, 250, 500, 250, 250, 500],
      'description': 'Simple piano tune',
    },
    'Sunrise': {
      'icon': 'wb_twilight',
      'frequencies': [329.63, 392.0, 440.0, 523.25, 587.33, 659.25],
      'durations': [350, 350, 350, 350, 350, 700],
      'description': 'Gradually rising warm tones',
    },
    'Zen Garden': {
      'icon': 'spa',
      'frequencies': [392.0, 0.0, 523.25, 0.0, 659.25],
      'durations': [500, 300, 500, 300, 800],
      'description': 'Meditation bowl strikes',
    },
    'Electronic Beat': {
      'icon': 'graphic_eq',
      'frequencies': [130.81, 261.63, 523.25, 261.63, 130.81, 261.63, 523.25],
      'durations': [100, 100, 100, 100, 100, 100, 200],
      'description': 'Electronic pulse pattern',
    },
    'Orchestral': {
      'icon': 'audiotrack',
      'frequencies': [440.0, 523.25, 659.25, 783.99, 880.0, 783.99, 659.25, 523.25, 440.0],
      'durations': [200, 200, 200, 200, 400, 200, 200, 200, 400],
      'description': 'Grand orchestral fanfare',
    },
    'Retro Phone': {
      'icon': 'phone',
      'frequencies': [440.0, 0.0, 440.0, 0.0, 440.0, 0.0, 440.0],
      'durations': [400, 200, 400, 200, 400, 200, 800],
      'description': 'Classic vintage telephone ring',
    },
    'Marimba': {
      'icon': 'music_note',
      'frequencies': [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25, 523.25],
      'durations': [150, 150, 150, 300, 150, 150, 300],
      'description': 'Upbeat marimba melody',
    },
    'Emergency Alert': {
      'icon': 'warning',
      'frequencies': [800.0, 1000.0, 800.0, 1000.0, 1200.0, 1000.0, 800.0],
      'durations': [150, 150, 150, 150, 300, 150, 400],
      'description': 'Urgent alert tone',
    },
    'Soft Ding': {
      'icon': 'notifications_active',
      'frequencies': [880.0, 0.0, 880.0, 0.0, 1108.73],
      'durations': [200, 100, 200, 100, 600],
      'description': 'Gentle notification chime',
    },
  };

  static List<String> get allInAppRingtoneNames => inAppRingtones.keys.toList();

  // ────────────────── Asset-Based Ringtones ──────────────────
  // These are pre-recorded ringtone files from assets/ringtones/
  static const Map<String, Map<String, dynamic>> assetRingtones = {
    'Electronic Alarm': {
      'asset': 'assets/ringtones/ALRMClok_Electronic alarm buzzer 1 (ID 0035)_BigSoundBank.com.wav',
      'icon': 'graphic_eq',
      'description': 'Electronic alarm buzzer',
    },
    'Mechanical Clock': {
      'asset': 'assets/ringtones/ALRMClok_Mechanical alarm clock long ring 2 (ID 1375)_BigSoundBank.com.wav',
      'icon': 'schedule',
      'description': 'Classic mechanical alarm clock',
    },
    'Clock Ring': {
      'asset': 'assets/ringtones/ALRMClok_Mechanical alarm clock ringtone 11 (ID 2814)_BigSoundBank.com.wav',
      'icon': 'alarm',
      'description': 'Traditional clock ringtone',
    },
    'Brazil Alarm': {
      'asset': 'assets/ringtones/jeremayjimenez-minas-gerais-brazil-eas-alarm-456936.mp3',
      'icon': 'public',
      'description': 'International alarm style',
    },
    'Saudi Alarm': {
      'asset': 'assets/ringtones/jeremayjimenez-saudi-arabia-eas-alarm-2024-my-own-alarm-422164.mp3',
      'icon': 'public',
      'description': 'Modern alarm tone',
    },
    'Classic Alarm': {
      'asset': 'assets/ringtones/u_inx5oo5fv3-alarm-327234.mp3',
      'icon': 'notifications',
      'description': 'Classic alarm sound',
    },
    'Ringtone': {
      'asset': 'assets/ringtones/universfield-ringtone-069-496274.mp3',
      'icon': 'phone',
      'description': 'Standard ringtone style',
    },
  };

  static List<String> get allAssetRingtoneNames => assetRingtones.keys.toList();

  /// Initialize or get the shared audio player
  AudioPlayer _getPlayer() {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Play the selected alarm sound based on the alarm configuration.
  /// Handles all sources: in-app tones, asset files, local files, and YouTube/URL.
  Future<void> playAlarmSound(Alarm alarm, {bool loop = true}) async {
    await stop(); // Stop any currently playing sound

    final player = _getPlayer();
    if (loop) {
      await player.setReleaseMode(ReleaseMode.loop);
    } else {
      await player.setReleaseMode(ReleaseMode.release);
    }

    // Prefer `soundPath` for playback; `sound` is display name.
    final soundKeyOrPath = alarm.soundPath.isNotEmpty ? alarm.soundPath : alarm.sound;

    try {
      // Check if it's an asset-based ringtone
      if (assetRingtones.containsKey(soundKeyOrPath)) {
        final assetPath = assetRingtones[soundKeyOrPath]!['asset'] as String;
        await player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
        debugPrint('AlarmSoundService: Playing asset ringtone: $soundKeyOrPath');
      } else if (_isYoutubeOrUrl(soundKeyOrPath)) {
        // YouTube/URL-based ringtone - play from URL
        await _playFromUrl(player, soundKeyOrPath);
        debugPrint('AlarmSoundService: Playing URL sound: $soundKeyOrPath');
      } else if (_isLocalFile(soundKeyOrPath)) {
        // Local file on device
        await player.play(DeviceFileSource(soundKeyOrPath));
        debugPrint('AlarmSoundService: Playing local file: $soundKeyOrPath');
      } else {
        // In-app ringtone -- use tone generator
        await _playInAppRingtone(player, soundKeyOrPath, loop: loop);
        debugPrint('AlarmSoundService: Playing in-app ringtone: $soundKeyOrPath');
      }

      _isPlaying = true;

      // Handle fade-in if enabled
      if (alarm.fadeInVolume) {
        _startFadeIn(player, alarm.initialVolume);
      } else {
        await player.setVolume(1.0);
      }
    } catch (e) {
      debugPrint('AlarmSoundService: Error playing sound "$soundKeyOrPath": $e');
      // Fallback: play default beep pattern
      try {
        await _playInAppRingtone(player, 'Default', loop: loop);
        _isPlaying = true;
        debugPrint('AlarmSoundService: Fallback to Default ringtone successful');
      } catch (fallbackError) {
        debugPrint('AlarmSoundService: Even fallback failed: $fallbackError');
      }
    }
  }

  /// Play sound for preview (non-looping, short)
  Future<void> playPreview(String soundName) async {
    await stop();
    final player = _getPlayer();
    await player.setReleaseMode(ReleaseMode.release);
    await player.setVolume(0.7);

    try {
      // Check if it's an asset-based ringtone
      if (assetRingtones.containsKey(soundName)) {
        final assetPath = assetRingtones[soundName]!['asset'] as String;
        await player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
      } else if (_isYoutubeOrUrl(soundName)) {
        await _playFromUrl(player, soundName);
      } else if (_isLocalFile(soundName)) {
        await player.play(DeviceFileSource(soundName));
      } else {
        await _playInAppRingtone(player, soundName, loop: false);
      }
      _isPlaying = true;

      // Auto-stop preview after 5 seconds
      Timer(const Duration(seconds: 5), () {
        if (_isPlaying) stop();
      });
    } catch (e) {
      debugPrint('AlarmSoundService: Preview error for "$soundName": $e');
    }
  }

  /// Stop all audio playback
  Future<void> stop() async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isPlaying = false;

    try {
      final player = _player;
      if (player != null) {
        await player.stop();
      }
    } catch (e) {
      debugPrint('AlarmSoundService: Error stopping: $e');
    }
  }

  /// Release all resources
  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
    _player = null;
  }

  // ────────────────── Private Helpers ──────────────────

  bool _isYoutubeOrUrl(String sound) {
    return sound.startsWith('http://') ||
        sound.startsWith('https://') ||
        sound.contains('youtube.com') ||
        sound.contains('youtu.be');
  }

  bool _isLocalFile(String sound) {
    return sound.startsWith('/') ||
        sound.startsWith('file://') ||
        sound.contains('\\') ||
        (sound.contains('/') && !sound.startsWith('default_'));
  }

  Future<void> _playFromUrl(AudioPlayer player, String url) async {
    if (_isYoutubeOrUrl(url) && (url.contains('youtube.com') || url.contains('youtu.be'))) {
      final localPath = await getOrDownloadYoutubeAudio(url);
      await player.play(DeviceFileSource(localPath));
      return;
    }

    await player.play(UrlSource(url));
  }

  String? _extractYoutubeId(String url) {
    // Handle youtube.com/watch?v=ID
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  Stream<double>? _youtubeDownloadProgress;
  String? _currentDownloadVideoId;

  Stream<double> downloadYoutubeAudio(String youtubeUrl, {void Function(double)? onProgress}) {
    final controller = StreamController<double>();
    
    _downloadYoutubeAudioInternal(youtubeUrl, controller, onProgress).then((path) {
      controller.close();
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });
    
    return controller.stream;
  }

  Future<String> _downloadYoutubeAudioInternal(
    String youtubeUrl, 
    StreamController<double> controller,
    void Function(double)? onProgress,
  ) async {
    try {
      final videoId = _extractYoutubeId(youtubeUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      _currentDownloadVideoId = videoId;

      final dir = await getApplicationDocumentsDirectory();
      final ytDir = Directory('${dir.path}/youtube_ringtones');
      if (!await ytDir.exists()) {
        await ytDir.create(recursive: true);
      }

      final outFile = File('${ytDir.path}/yt_$videoId.m4a');
      if (await outFile.exists() && await outFile.length() > 32 * 1024) {
        controller.add(1.0);
        return outFile.path;
      }

      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final audio = manifest.audioOnly.withHighestBitrate();
        final totalBytes = audio.size.totalBytes;
        final stream = yt.videos.streamsClient.get(audio);

        int downloadedBytes = 0;
        final sink = outFile.openWrite();
        try {
          await for (final chunk in stream) {
            sink.add(chunk);
            downloadedBytes += chunk.length;
            if (totalBytes > 0) {
              final progress = downloadedBytes / totalBytes;
              controller.add(progress);
              onProgress?.call(progress);
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        if (!await outFile.exists() || await outFile.length() < 32 * 1024) {
          throw Exception('Downloaded audio file is too small');
        }

        controller.add(1.0);
        return outFile.path;
      } finally {
        yt.close();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getOrDownloadYoutubeAudio(String youtubeUrl, {void Function(double)? onProgress}) async {
    // Check memory cache first
    final videoId = _extractYoutubeId(youtubeUrl);
    if (videoId == null) {
      throw Exception('Invalid YouTube URL');
    }
    
    // Check if already in memory cache
    if (_youtubeCache.containsKey(videoId)) {
      final cachedPath = _youtubeCache[videoId]!;
      if (await File(cachedPath).exists()) {
        onProgress?.call(1.0);
        return cachedPath;
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final ytDir = Directory('${dir.path}/youtube_ringtones');
    if (!await ytDir.exists()) {
      await ytDir.create(recursive: true);
    }

    final outFile = File('${ytDir.path}/yt_$videoId.m4a');
    
    // Check file cache
    if (await outFile.exists() && await outFile.length() > 32 * 1024) {
      _youtubeCache[videoId] = outFile.path;
      onProgress?.call(1.0);
      return outFile.path;
    }

    final yt = YoutubeExplode();
    try {
      // Get video info first for faster processing
      final video = await yt.videos.get(videoId);
      
      // Get audio streams - use lower quality for faster download
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      
      // Get a good quality audio stream (not necessarily highest for speed)
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        throw Exception('No audio stream available');
      }
      
      // Prefer medium bitrate for faster download, fallback to highest if needed
      final audio = audioStreams.firstWhere(
        (s) => s.bitrate.bitsPerSecond >= 128000 && s.bitrate.bitsPerSecond <= 192000,
        orElse: () => audioStreams.withHighestBitrate(),
      );
      
      final totalBytes = audio.size.totalBytes;
      final stream = yt.videos.streamsClient.get(audio);

      int downloadedBytes = 0;
      final sink = outFile.openWrite();
      try {
        await for (final chunk in stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            final progress = downloadedBytes / totalBytes;
            onProgress?.call(progress);
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (!await outFile.exists() || await outFile.length() < 32 * 1024) {
        throw Exception('Downloaded audio file is too small');
      }

      // Cache the result
      _youtubeCache[videoId] = outFile.path;
      onProgress?.call(1.0);
      
      return outFile.path;
    } finally {
      yt.close();
    }
  }

  /// Play in-app synthesized ringtone.
  /// Generates a WAV file in temp directory and plays it.
  Future<void> _playInAppRingtone(
    AudioPlayer player,
    String name, {
    bool loop = true,
  }) async {
    final ringtone = inAppRingtones[name] ?? inAppRingtones['Default']!;
    final frequencies = (ringtone['frequencies'] as List).cast<double>();
    final durations = (ringtone['durations'] as List).cast<int>();

    // Generate WAV audio data from the frequency/duration pattern
    final wavBytes = _generateWavFromFrequencies(frequencies, durations);

    // Write to temp file and play
    final tempDir = await getTemporaryDirectory();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final tempFile = File('${tempDir.path}/ringtone_$safeName.wav');
    await tempFile.writeAsBytes(wavBytes);

    await player.play(DeviceFileSource(tempFile.path));
  }

  /// Generate a WAV file in memory from a list of frequencies and durations.
  Uint8List _generateWavFromFrequencies(
    List<double> frequencies,
    List<int> durationsMs,
  ) {
    const sampleRate = 44100;
    const bitsPerSample = 16;
    const numChannels = 1;

    // Calculate total samples
    int totalSamples = 0;
    for (final dms in durationsMs) {
      totalSamples += (sampleRate * dms / 1000).round();
    }

    // Repeat the pattern to make it longer (at least ~3 seconds for looping)
    final patternSamples = totalSamples;
    final repeatCount = max(1, (sampleRate * 3 / patternSamples).ceil());
    totalSamples *= repeatCount;

    final bytesPerSample = bitsPerSample ~/ 8;
    final dataSize = totalSamples * numChannels * bytesPerSample;

    // Build WAV header + data
    final buffer = ByteData(44 + dataSize);

    // RIFF chunk
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt sub-chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // space
    buffer.setUint32(16, 16, Endian.little); // SubChunk1Size (PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little);
    buffer.setUint16(32, numChannels * bytesPerSample, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    // Generate audio samples
    int sampleIndex = 0;
    for (int rep = 0; rep < repeatCount; rep++) {
      for (int i = 0; i < frequencies.length; i++) {
        final freq = frequencies[i];
        final durationSamples = (sampleRate * durationsMs[i] / 1000).round();

        for (int s = 0; s < durationSamples; s++) {
          double sample;
          if (freq <= 0) {
            sample = 0; // Silence
          } else {
            // Sine wave with envelope for smoother sound
            final t = s / sampleRate;
            final envelope = _envelope(s, durationSamples);
            sample = sin(2 * pi * freq * t) * envelope * 0.7;
          }

          final intSample = (sample * 32767).clamp(-32768, 32767).toInt();
          buffer.setInt16(44 + sampleIndex * 2, intSample, Endian.little);
          sampleIndex++;
        }
      }

      // Add a small gap between repetitions (200ms silence)
      if (rep < repeatCount - 1) {
        final gapSamples = (sampleRate * 0.2).round();
        // Don't exceed buffer if we've already calculated totalSamples correctly
        // The gap is part of the pattern, but for safety:
        // Actually let's not add extra — the pattern itself should be enough
      }
    }

    return buffer.buffer.asUint8List();
  }

  /// ADSR-like envelope to make tones sound smoother
  double _envelope(int sampleIndex, int totalSamples) {
    final attackSamples = min(totalSamples ~/ 10, 441); // 10ms attack
    final releaseSamples = min(totalSamples ~/ 5, 882); // 20ms release

    if (sampleIndex < attackSamples) {
      return sampleIndex / attackSamples; // Attack
    } else if (sampleIndex > totalSamples - releaseSamples) {
      return (totalSamples - sampleIndex) / releaseSamples; // Release
    }
    return 1.0; // Sustain
  }

  /// Fade-in effect: gradually increase volume
  void _startFadeIn(AudioPlayer player, double startVolume) {
    const fadeDuration = Duration(seconds: 30);
    const stepInterval = Duration(milliseconds: 500);
    final steps = fadeDuration.inMilliseconds ~/ stepInterval.inMilliseconds;
    final increment = (1.0 - startVolume) / steps;
    var currentVolume = startVolume;

    player.setVolume(currentVolume);

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(stepInterval, (timer) {
      currentVolume += increment;
      if (currentVolume >= 1.0) {
        currentVolume = 1.0;
        timer.cancel();
      }
      try {
        player.setVolume(currentVolume);
      } catch (_) {
        timer.cancel();
      }
    });
  }

  // ────────────────── Saved Ringtone Preferences ──────────────────

  /// Save user's selected ringtone path for an alarm
  static Future<void> saveAlarmRingtone(
    String alarmId,
    String ringtonePath,
    String ringtoneSource,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ringtone_$alarmId', ringtonePath);
    await prefs.setString('ringtone_source_$alarmId', ringtoneSource);
  }

  /// Get user's saved ringtone for an alarm
  static Future<String?> getAlarmRingtone(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ringtone_$alarmId');
  }

  /// Get the ringtone source type for an alarm
  static Future<String?> getAlarmRingtoneSource(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ringtone_source_$alarmId');
  }
}
