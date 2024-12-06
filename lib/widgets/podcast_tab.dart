import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast_player_model.dart';

class PodcastTab extends StatelessWidget {
  const PodcastTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerModel = Provider.of<PodcastPlayerModel>(context);

    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue,
            child: const Text(
              "Podcasts",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          ListTile(
            title: const Text("Sample Podcast"),
            onTap: () {
              playerModel.loadPodcast(
                "https://example.com/sample_podcast.mp3",
                "Sample Podcast",
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Another Podcast"),
            onTap: () {
              playerModel.loadPodcast(
                "https://example.com/another_podcast.mp3",
                "Another Podcast",
              );
            },
          ),
        ],
      ),
    );
  }
}
