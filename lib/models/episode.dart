import 'package:flutter/foundation.dart';

@immutable
class Episode {
  final String title;
  final String description;
  final String audioUrl;
  final Duration duration;
  final DateTime publishDate;

  const Episode({
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.publishDate,
  });

  @override
  String toString() {
    return 'Episode{title: $title, audioUrl: $audioUrl, duration: $duration, publishDate: $publishDate}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Episode &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          audioUrl == other.audioUrl &&
          duration == other.duration &&
          publishDate == other.publishDate;

  @override
  int get hashCode =>
      title.hashCode ^
      audioUrl.hashCode ^
      duration.hashCode ^
      publishDate.hashCode;
}
