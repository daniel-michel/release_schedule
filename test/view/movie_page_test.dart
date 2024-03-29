import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_page.dart';

void main() {
  group('MoviePage', () {
    late MovieManager manager;
    late MovieData movie;

    setUp(() {
      movie = MovieData()
        ..setNewDetails(
          labels: [(text: 'The Shawshank Redemption', language: 'en')],
          releaseDates: [
            DateWithPrecisionAndPlace(
                DateTime(1994, 9, 22), DatePrecision.day, 'US')
          ],
        );
      manager = MovieManager(
        MovieApi(),
        InMemoryMovieStorage(),
      );
      manager.addMovies([movie]);
    });

    testWidgets('should render the movie details', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviePage(movie: movie, manager: manager),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(movie.title!), findsAtLeastNWidgets(1));
    });

    testWidgets('should bookmark the movie', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviePage(movie: movie, manager: manager),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(movie.bookmarked, isFalse);

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();

      expect(movie.bookmarked, isTrue);
    });
    testWidgets("should display the movie's genres",
        (WidgetTester tester) async {
      movie.setNewDetails(genres: ['Drama']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviePage(movie: movie, manager: manager),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets("should display the movie's titles and release dates",
        (WidgetTester tester) async {
      movie.setNewDetails(
        titles: [(text: 'The Shawshank Redemption', language: 'en')],
        releaseDates: [
          DateWithPrecisionAndPlace(
              DateTime(1994, 9, 22), DatePrecision.day, 'US')
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviePage(movie: movie, manager: manager),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('en'), findsOneWidget);
      expect(find.text('The Shawshank Redemption'), findsNWidgets(3));

      expect(find.text('US'), findsOneWidget);
      expect(find.textContaining('1994'), findsNWidgets(2));
    });
  });
}
