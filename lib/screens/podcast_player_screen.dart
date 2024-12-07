import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast_player_model.dart';
import '../widgets/podcast_tab.dart';
import '../widgets/add_podcast_dialog.dart';
import '../widgets/podcast_grid.dart';
import '../widgets/episode_list.dart';
import '../widgets/audio_player_widget.dart';
import 'dart:developer' as developer;

class PodcastPlayerScreen extends StatelessWidget {
  const PodcastPlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerModel>(
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          title: Text(model.currentEpisodes != null ? 'Episodes' : 'Podcast Player'),
          leading: model.currentEpisodes != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => model.clearEpisodes(),
                )
              : null,
          actions: [
            if (model.currentEpisodes == null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => const AddPodcastDialog(),
                    );
                    
                    if (result != null) {
                      model.addPodcast(
                        result['name'],
                        result['url'],
                        result['imageUrl'],
                      );
                    }
                  },
                  child: const Text('Add Podcast'),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const PodcastTab(),
                        Expanded(
                          child: model.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : model.currentEpisodes != null
                                  ? EpisodeList(
                                      episodes: model.currentEpisodes!,
                                      onEpisodeSelected: (episode) {
                                        developer.log('Episode selected: ${episode.title}');
                                        model.playEpisode(episode);
                                      },
                                    )
                                  : model.podcasts.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "Add your first podcast using the button above",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        )
                                      : PodcastGrid(
                                          podcasts: model.podcasts,
                                          onPodcastSelected: (podcast) {
                                            model.loadPodcastEpisodes(podcast.url);
                                          },
                                        ),
                        ),
                      ],
                    ),
                  ),
                  // Add padding at the bottom to account for the audio player
                  if (model.currentEpisode != null)
                    const SizedBox(height: 100),
                ],
              ),
              // Position the audio player at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AudioPlayerWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
