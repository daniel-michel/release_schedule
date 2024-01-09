import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:release_schedule/view/movie_page.dart';

void main() {
  testWidgets('MovieItem displays movie data', (WidgetTester tester) async {
    final movie = MovieData(
      'Test Movie',
      DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US'),
    );
    movie.setDetails(
      genres: ['Action', 'Adventure'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieItem(movie),
        ),
      ),
    );

    expect(find.text('Test Movie'), findsOneWidget);

    expect(find.textContaining('Action, Adventure'), findsOneWidget);
  });

  testWidgets('should update when the movie is modified', (tester) async {
    final movie = MovieData(
      'Test Movie',
      DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US'),
    );
    movie.setDetails(
      genres: ['Action', 'Adventure'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieItem(movie),
        ),
      ),
    );

    expect(find.text('Test Movie'), findsOneWidget);

    movie.setDetails(
      genres: ['Action', 'Adventure', 'Comedy'],
    );

    await tester.pump();

    expect(find.textContaining('Action, Adventure, Comedy'), findsOneWidget);
  });

  testWidgets('should update when the movie is bookmarked', (tester) async {
    final movie = MovieData(
      'Test Movie',
      DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US'),
    );
    movie.setDetails(
      genres: ['Action', 'Adventure'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieItem(movie),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    movie.setDetails(
      bookmarked: true,
    );

    await tester.pump();

    expect(find.byIcon(Icons.bookmark_added), findsOneWidget);
  });

  testWidgets("should update the bookmark state when the icon is tapped",
      (tester) async {
    final movie = MovieData(
      'Test Movie',
      DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US'),
    );
    movie.setDetails(
      genres: ['Action', 'Adventure'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieItem(movie),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_outline));

    await tester.pump();

    expect(find.byIcon(Icons.bookmark_added), findsOneWidget);
  });

  testWidgets("should navigate to MoviePage when tapped", (tester) async {
    final movie = MovieData(
      'Test Movie',
      DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US'),
    );
    movie.setDetails(
      genres: ['Action', 'Adventure'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieItem(movie),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byType(ListTile));

    await tester.pumpAndSettle();

    expect(find.byType(MoviePage), findsOneWidget);
  });
}
