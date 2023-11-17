import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:release_schedule/view/movie_list.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  group('MovieManagerList', () {
    testWidgets('displays movie list', (tester) async {
      final manager = MovieManager(MovieApi(), LocalMovieStorage());
      manager.addMovies([
        MovieData(
            'Movie 1',
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'US')),
        MovieData(
            'Movie 2',
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'US')),
      ]);
      // pump the delay until the change is written to the cache, so no timers run when the test finishes
      await tester.pump(const Duration(seconds: 5));

      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MovieManagerList(manager))));

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(MovieList), findsOneWidget);
    });

    testWidgets('updates when new movies are added', (tester) async {
      final manager = MovieManager(MovieApi(), LocalMovieStorage());
      manager.addMovies([
        MovieData(
            'Movie 1',
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'US')),
        MovieData(
            'Movie 2',
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'US')),
      ]);

      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MovieManagerList(manager))));

      manager.addMovies([
        MovieData(
            'Movie 3',
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'US')),
      ]);
      // pump the delay until the change is written to the cache, so no timers run when the test finishes
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(MovieList), findsOneWidget);
      expect(find.byType(MovieItem), findsNWidgets(3));
    });
  });
}
