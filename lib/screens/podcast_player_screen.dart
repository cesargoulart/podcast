import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast_player_model.dart';
import '../widgets/podcast_tab.dart';
import '../widgets/add_podcast_dialog.dart';
import '../widgets/podcast_grid.dart';
import '../widgets/episode_list.dart';

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
            if (model.currentEpisodes == null) // Only show Add Podcast button in grid view
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
        body: Row(
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
                          onEpisodeSelected: model.playEpisode,
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
    );
  }
}
