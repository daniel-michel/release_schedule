import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';

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

    final formattedDate = movie.releaseDate.toString();
    expect(find.textContaining(formattedDate), findsOneWidget);

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
}
