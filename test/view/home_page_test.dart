import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/main.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  group('HomePage', () {
    late LocalMovieStorage storage;

    setUp(() {
      storage = InMemoryMovieStorage();
      storage.update([
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
          ),
        MovieData()
          ..setNewDetails(
            labels: [(text: 'The Dark Knight', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(2008, 7, 18), DatePrecision.day, 'US')
            ],
          ),
      ]);
    });

    testWidgets('displays search bar', (WidgetTester tester) async {
      MovieManager movieManager = MovieManager(MovieApi(), storage);
      await tester.pumpWidget(MaterialApp(home: HomePage(movieManager)));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('displays list of releases', (WidgetTester tester) async {
      MovieManager movieManager = MovieManager(MovieApi(), storage);
      await tester.pumpWidget(MaterialApp(home: HomePage(movieManager)));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(MovieManagerList), findsOneWidget);
    });

    testWidgets('displays search results', (WidgetTester tester) async {
      MovieManager movieManager = MovieManager(MovieApi(), storage);
      await tester.pumpWidget(MaterialApp(home: HomePage(movieManager)));

      await tester.enterText(
          find.byType(TextField), 'The Shawshank Redemption');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('The Shawshank Redemption'), findsNWidgets(2));
    });
  });
}
