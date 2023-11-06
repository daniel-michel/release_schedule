import 'package:flutter/material.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata_movie_api.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_list.dart';

void main() {
  runApp(const MyApp());
  movieManager.loadUpcomingMovies();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Schedule',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final MovieApi api = WikidataMovieApi();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Release Schedule")),
      body: AnimatedBuilder(
        animation: movieManager,
        // future: api.getUpcomingMovies(),
        builder: (context, widget) {
          return MovieList(movieManager.movies);
          // var data = snapshot.data;
          // if (snapshot.hasData && data != null) {
          //   return MovieList(data);
          // } else if (snapshot.hasError) {
          //   return ErrorWidget(snapshot.error ?? "Something went wrong");
          // }
          // return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
