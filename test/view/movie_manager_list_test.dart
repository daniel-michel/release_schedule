import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:release_schedule/view/movie_list.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  group('MovieManagerList', () {
    late List<MovieData> movies;

    setUp(() {
      movies = [
        MovieData()
          ..setNewDetails(
            labels: [(text: 'Movie 1', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndPlace(
                  DateTime(2023, 1, 1), DatePrecision.day, 'US')
            ],
          ),
        MovieData()
          ..setNewDetails(
            labels: [(text: 'Movie 2', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndPlace(
                  DateTime(2023, 1, 1), DatePrecision.day, 'US')
            ],
          )
      ];
    });
    testWidgets('displays movie list', (tester) async {
      final manager = MovieManager(MovieApi(), InMemoryMovieStorage());
      manager.addMovies(movies);
      // pump the delay until the change is written to the cache, so no timers run when the test finishes
      await tester.pump(const Duration(seconds: 5));

      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MovieManagerList(manager))));

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(MovieList), findsOneWidget);
    });

    testWidgets('updates when new movies are added', (tester) async {
      final manager = MovieManager(MovieApi(), InMemoryMovieStorage());
      manager.addMovies(movies);

      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MovieManagerList(manager))));

      manager.addMovies([
        MovieData()
          ..setNewDetails(
            labels: [(text: 'Movie 3', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndPlace(
                  DateTime(2023, 1, 1), DatePrecision.day, 'US')
            ],
          )
      ]);
      // pump the delay until the change is written to the cache, so no timers run when the test finishes
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(MovieList), findsOneWidget);
      expect(find.byType(MovieItem), findsNWidgets(3));
    });
  });
}
