import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';

void main() {
  group('MovieManager', () {
    late MovieManager movieManager;

    final theMatrix = MovieData()
      ..setNewDetails(
        labels: [(text: 'The Matrix', language: 'en')],
        releaseDates: [
          DateWithPrecisionAndCountry(
              DateTime(1999, 3, 31), DatePrecision.day, 'USA')
        ],
      );
    final theMatrixReloaded = MovieData()
      ..setNewDetails(
        labels: [(text: 'The Matrix Reloaded', language: 'en')],
        releaseDates: [
          DateWithPrecisionAndCountry(
              DateTime(2003, 5, 7), DatePrecision.day, 'USA')
        ],
      );

    setUp(() {
      movieManager = MovieManager(
        MovieApi(),
        InMemoryMovieStorage(),
      );
    });

    test('addMovies should add movies to the list', () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals(movies));
    });

    test('addMovies should add new movies', () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
      ];

      movieManager.addMovies(movies);

      final newMovies = [
        MovieData()
          ..setNewDetails(
            labels: [(text: 'The Matrix Revolutions', language: 'en')],
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(2003, 11, 5), DatePrecision.day, 'USA')
            ],
          ),
      ];

      movieManager.addMovies(newMovies);

      expect(movieManager.movies, equals(movies + newMovies));
    });

    test('addMovies should update existing movies', () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
      ];

      movieManager.addMovies(movies);

      final updatedMovie = MovieData()
        ..setNewDetails(
          bookmarked: true,
          genres: ['Action', 'Adventure'],
          labels: [(text: 'The Matrix Reloaded', language: 'en')],
          releaseDates: [
            DateWithPrecisionAndCountry(
                DateTime(2003, 5, 7), DatePrecision.day, 'USA')
          ],
        );

      movieManager.addMovies([updatedMovie]);

      expect(movieManager.movies[1].genres, equals(updatedMovie.genres));
      expect(movieManager.movies[1].bookmarked, equals(false));
    });

    test('addMovies should sort movies by their release dates', () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals(movies.reversed.toList()));
    });

    test(
        'addMovies should sort movies that have a less precise release date before movies with more precise release dates',
        () {
      final movies = [
        MovieData()
          ..updateWithNewIgnoringUserControlled(theMatrixReloaded)
          ..setNewDetails(
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(2003, 5, 7), DatePrecision.day, 'USA')
            ],
          ),
        MovieData()
          ..updateWithNewIgnoringUserControlled(theMatrix)
          ..setNewDetails(
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(2003, 5, 7), DatePrecision.month, 'USA')
            ],
          ),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals([...movies.reversed]));
    });

    test(
        'when a movie is modified and it\'s date is changed the movies should be resorted',
        () async {
      final movies = [
        MovieData()
          ..updateWithNewIgnoringUserControlled(theMatrixReloaded)
          ..setNewDetails(
            releaseDates: [
              DateWithPrecisionAndCountry(
                  DateTime(1998, 5, 7), DatePrecision.day, 'USA')
            ],
          ),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
      ];

      movieManager.addMovies(movies);

      final movie = movieManager.movies.first;
      movie.setNewDetails(
        releaseDates: [
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America')
        ],
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(movieManager.movies, equals(movies.reversed.toList()));
    });

    test('removeMoviesWhere should remove movies from the list', () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
      ];
      MovieData notRemoved = MovieData()
        ..setNewDetails(
          labels: [
            (text: 'Harry Potter and the Philosopher\'s Stone', language: 'en')
          ],
          releaseDates: [
            DateWithPrecisionAndCountry(
                DateTime(2001, 11, 4), DatePrecision.day, 'UK')
          ],
        );

      movieManager.addMovies(movies + [notRemoved]);

      movieManager.removeMoviesWhere(
          (movie) => movie.title?.contains('Matrix') == true);

      expect(movieManager.movies, equals([notRemoved]));
    });

    test("localSearch", () {
      final movies = [
        MovieData()..updateWithNewIgnoringUserControlled(theMatrix),
        MovieData()..updateWithNewIgnoringUserControlled(theMatrixReloaded),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.localSearch('Matrix'), equals(movies));
      expect(movieManager.localSearch('Matrix Re'),
          equals(movies.reversed.toList()));
      expect(movieManager.localSearch('Matrix Reloaded'), equals([movies[1]]));
      expect(movieManager.localSearch('Matrix Revolutions'), equals([]));
    });
  });
}
