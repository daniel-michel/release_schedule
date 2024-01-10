import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:release_schedule/view/movie_list.dart';

void main() {
  group('MovieList', () {
    late List<MovieData> movies;

    setUp(() {
      movies = [
        MovieData()
          ..setNewDetails(
            labels: [(text: 'The Shawshank Redemption', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(1994, 9, 22), DatePrecision.day, 'US')
            ],
          ),
        MovieData()
          ..setNewDetails(
            labels: [(text: 'The Godfather', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(1972, 3, 24), DatePrecision.day, 'US')
            ],
          )
      ];
    });

    testWidgets('should render a list of movies', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieList(movies),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MovieItem), findsNWidgets(movies.length));
    });

    testWidgets("should filter the list of movies",
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovieList(
              movies,
              filter: (movie) => movie.title?.contains('Godfather') == true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MovieItem), findsOneWidget);
    });
  });
}
