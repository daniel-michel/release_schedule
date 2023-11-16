import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/main.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  group('HomePage', () {
    testWidgets('displays title', (WidgetTester tester) async {
      MovieManager movieManager = MovieManager(MovieApi(), LocalMovieStorage());
      await tester.pumpWidget(MaterialApp(home: HomePage(movieManager)));

      expect(find.text('Release Schedule'), findsOneWidget);
    });

    testWidgets('displays list of releases', (WidgetTester tester) async {
      MovieManager movieManager = MovieManager(MovieApi(), LocalMovieStorage());
      await tester.pumpWidget(MaterialApp(home: HomePage(movieManager)));

      expect(find.byType(MovieManagerList), findsOneWidget);
    });
  });
}
