import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/podcast_player_screen.dart';
import 'models/podcast_player_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PodcastPlayerModel(),
      child: MaterialApp(
        title: 'Podcast Player',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const PodcastPlayerScreen(),
      ),
    );
  }
}
