import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
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

  PodcastPlayerModel() {
    _audioPlayer.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });
    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentPodcast => _currentPodcast;
  List<Podcast> get podcasts => List.unmodifiable(_podcasts);
  List<Episode>? get currentEpisodes => _currentEpisodes;
  bool get isLoading => _isLoading;

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
          final duration = item.findElements('itunes:duration').firstOrNull?.text ?? '0:00';
          
          return Episode(
            title: item.findElements('title').firstOrNull?.text ?? 'Untitled Episode',
            description: item.findElements('description').firstOrNull?.text ?? 'No description available',
            audioUrl: enclosure?.getAttribute('url') ?? '',
            duration: _parseDuration(duration),
            publishDate: DateTime.tryParse(
              item.findElements('pubDate').firstOrNull?.text ?? DateTime.now().toIso8601String()
            ) ?? DateTime.now(),
          );
        }).toList();

        // Sort episodes by publish date (newest first)
        _currentEpisodes!.sort((a, b) => b.publishDate.compareTo(a.publishDate));
      } else {
        debugPrint('Failed to load podcast feed: ${response.statusCode}');
        _currentEpisodes = [];
      }
    } catch (e) {
      debugPrint('Error loading podcast feed: $e');
      _currentEpisodes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Duration _parseDuration(String duration) {
    try {
      // Handle different duration formats
      if (duration.contains(':')) {
        final parts = duration.split(':').map(int.parse).toList();
        if (parts.length == 3) {
          return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
        } else if (parts.length == 2) {
          return Duration(minutes: parts[0], seconds: parts[1]);
        }
      } else {
        return Duration(seconds: int.tryParse(duration) ?? 0);
      }
    } catch (e) {
      debugPrint('Error parsing duration: $e');
    }
    return Duration.zero;
  }

  Future<void> loadPodcast(String url, String title) async {
    try {
      await _audioPlayer.setUrl(url);
      _currentPodcast = title;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading podcast: $e");
    }
  }

  Future<void> playEpisode(Episode episode) async {
    try {
      await _audioPlayer.setUrl(episode.audioUrl);
      _currentPodcast = episode.title;
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing episode: $e');
    }
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seek(double seconds) {
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
  }

  void forward() {
    _audioPlayer.seek(position + const Duration(seconds: 10));
  }

  void rewind() {
    _audioPlayer.seek(position - const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
