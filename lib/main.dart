import 'package:flutter/material.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata_movie_api.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  runApp(const MyApp());
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
      home: HomePage(movieManager),
    );
  }
}

class HomePage extends StatelessWidget {
  final MovieApi api = WikidataMovieApi();
  final MovieManager manager;

  HomePage(this.manager, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Release Schedule"),
        actions: [
          FilledButton(
              onPressed: () => manager.removeMoviesWhere((movie) => true),
              child: const Icon(Icons.delete))
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  Scaffold(
                    body: MovieManagerList(manager),
                    floatingActionButton: FloatingActionButton(
                      child: const Icon(Icons.refresh),
                      onPressed: () => manager.loadUpcomingMovies(),
                    ),
                  ),
                  MovieManagerList(manager, filter: (movie) => movie.bookmarked)
                ],
              ),
            ),
            const TabBar(tabs: [
              Tab(icon: Icon(Icons.list), child: Text("Upcoming")),
              Tab(icon: Icon(Icons.bookmark), child: Text("Bookmarked")),
            ]),
          ],
        ),
      ),
    );
  }
}
