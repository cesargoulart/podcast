import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/podcast_player_screen.dart';
import 'models/podcast_player_model.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    developer.log('Initializing audio background service...');
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.podcast.channel.audio',
      androidNotificationChannelName: 'Podcast Audio',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    );
    developer.log('Audio background service initialized successfully');
  } catch (e, st) {
    developer.log('Error initializing audio background service', error: e, stackTrace: st);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PodcastPlayerModel(),
      child: MaterialApp(
        title: 'Podcast App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const PodcastPlayerScreen(),
      ),
    );
  }
}
