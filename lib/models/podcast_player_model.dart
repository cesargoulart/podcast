import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:developer' as developer;
import 'podcast.dart';
import 'episode.dart';

class PodcastPlayerModel extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Podcast> _podcasts = [];
  List<Episode>? _currentEpisodes;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentPodcast;
  bool _isLoading = false;
  Episode? _currentEpisode;

  PodcastPlayerModel() {
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Configure the audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Listen to audio player state changes
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        developer.log(
            'Player state changed: ${state.playing ? "playing" : "paused"}');
        notifyListeners();
      });

      _audioPlayer.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      });

      _audioPlayer.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      });

      _audioPlayer.processingStateStream.listen((state) {
        developer.log('Processing state: $state');
        if (state == ProcessingState.completed) {
          _position = Duration.zero;
          _isPlaying = false;
          notifyListeners();
        }
      });

      // Listen for errors
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          developer.log('A stream error occurred: $e',
              error: e, stackTrace: st);
        },
      );
    } catch (e, st) {
      developer.log('Error initializing audio player: $e',
          error: e, stackTrace: st);
    }
  }

  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentPodcast => _currentPodcast;
  List<Podcast> get podcasts => List.unmodifiable(_podcasts);
  List<Episode>? get currentEpisodes => _currentEpisodes;
  bool get isLoading => _isLoading;
  Episode? get currentEpisode => _currentEpisode;

  void clearEpisodes() {
    _currentEpisodes = null;
    notifyListeners();
  }

  void addPodcast(String name, String url, String imageUrl) {
    _podcasts.add(Podcast(name: name, url: url, imageUrl: imageUrl));
    notifyListeners();
  }

  Future<void> loadPodcastEpisodes(String url) async {
    _isLoading = true;
    _currentEpisodes = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        _currentEpisodes = items.map((item) {
          final enclosure = item.findElements('enclosure').firstOrNull;
          final duration =
              item.findElements('itunes:duration').firstOrNull?.text ?? '0:00';
          final audioUrl = enclosure?.getAttribute('url') ?? '';

          // Log the extracted audio URL
          developer.log(
              'Extracted audio URL: $audioUrl for episode: ${item.findElements("title").firstOrNull?.text}');

          return Episode(
            title: item.findElements('title').firstOrNull?.text ??
                'Untitled Episode',
            description: item.findElements('description').firstOrNull?.text ??
                'No description available',
            audioUrl: audioUrl,
            duration: _parseDuration(duration),
            publishDate: DateTime.tryParse(
                    item.findElements('pubDate').firstOrNull?.text ??
                        DateTime.now().toIso8601String()) ??
                DateTime.now(),
          );
        }).toList();

        _currentEpisodes!
            .sort((a, b) => b.publishDate.compareTo(a.publishDate));
      } else {
        developer.log('Failed to load podcast feed: ${response.statusCode}');
        _currentEpisodes = [];
      }
    } catch (e, st) {
      developer.log('Error loading podcast feed: $e', error: e, stackTrace: st);
      _currentEpisodes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> playEpisode(Episode episode) async {
    try {
      _currentEpisode = episode;
      developer.log('Playing episode: ${episode.title} from URL: ${episode.audioUrl}');

      // Set the audio source with metadata for background playback
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(episode.audioUrl),
          tag: MediaItem(
            id: episode.audioUrl,
            album: "Podcast",
            title: episode.title,
            artUri: null,
          ),
        ),
      );
      
      developer.log('Audio source set successfully');
      await _audioPlayer.play();
      developer.log('Playback started successfully');
      
      notifyListeners();
    } catch (e, st) {
      developer.log('Error playing episode: $e', error: e, stackTrace: st);
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_currentEpisode == null) return;

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e, st) {
      developer.log('Error toggling play/pause: $e', error: e, stackTrace: st);
    }
  }

  Future<void> seek(double seconds) async {
    try {
      await _audioPlayer.seek(Duration(seconds: seconds.toInt()));
    } catch (e, st) {
      developer.log('Error seeking: $e', error: e, stackTrace: st);
    }
  }

  Future<void> forward() async {
    try {
      final newPosition = _position + const Duration(seconds: 10);
      if (newPosition <= _duration) {
        await _audioPlayer.seek(newPosition);
      }
    } catch (e, st) {
      developer.log('Error forwarding: $e', error: e, stackTrace: st);
    }
  }

  Future<void> rewind() async {
    try {
      final newPosition = _position - const Duration(seconds: 10);
      if (newPosition >= Duration.zero) {
        await _audioPlayer.seek(newPosition);
      } else {
        await _audioPlayer.seek(Duration.zero);
      }
    } catch (e, st) {
      developer.log('Error rewinding: $e', error: e, stackTrace: st);
    }
  }

  Duration _parseDuration(String duration) {
    try {
      if (duration.contains(':')) {
        final parts = duration.split(':').map(int.parse).toList();
        if (parts.length == 3) {
          return Duration(
              hours: parts[0], minutes: parts[1], seconds: parts[2]);
        } else if (parts.length == 2) {
          return Duration(minutes: parts[0], seconds: parts[1]);
        }
      } else {
        return Duration(seconds: int.tryParse(duration) ?? 0);
      }
    } catch (e, st) {
      developer.log('Error parsing duration: $e', error: e, stackTrace: st);
    }
    return Duration.zero;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
