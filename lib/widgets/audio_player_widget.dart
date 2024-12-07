import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast_player_model.dart';
import 'dart:developer' as developer;

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerModel>(
      builder: (context, model, child) {
        if (model.currentEpisode == null) {
          return const SizedBox.shrink();
        }

        developer.log('Building audio player widget with episode: ${model.currentEpisode?.title}');

        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Title and progress
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.currentEpisode?.title ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(_formatDuration(model.position)),
                            Expanded(
                              child: Slider(
                                value: model.position.inSeconds.toDouble(),
                                max: model.duration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  model.seek(value);
                                },
                              ),
                            ),
                            Text(_formatDuration(model.duration)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Playback controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        onPressed: () {
                          developer.log('Rewind button pressed');
                          model.rewind();
                        },
                      ),
                      IconButton(
                        iconSize: 48,
                        icon: Icon(
                          model.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        ),
                        onPressed: () {
                          developer.log('Play/Pause button pressed');
                          model.togglePlayPause();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        onPressed: () {
                          developer.log('Forward button pressed');
                          model.forward();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
