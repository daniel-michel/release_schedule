import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';

void main() {
  group('MovieManager', () {
    late MovieManager movieManager;

    setUp(() {
      movieManager = MovieManager(
        MovieApi(),
        InMemoryMovieStorage(),
      );
    });

    test('addMovies should add movies to the list', () {
      final movies = [
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals(movies));
    });

    test('addMovies should add new movies', () {
      final movies = [
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      final newMovies = [
        MovieData(
          'The Matrix Revolutions',
          DateWithPrecisionAndCountry(DateTime(2003, 11, 5), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(newMovies);

      expect(movieManager.movies, equals([...movies, ...newMovies]));
    });

    test('addMovies should update existing movies', () {
      final movies = [
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      final updatedMovie = MovieData(
        'The Matrix Reloaded',
        DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
            'United States of America'),
      )..setDetails(
          bookmarked: true,
          genres: ['Action', 'Adventure'],
        );

      movieManager.addMovies([updatedMovie]);

      expect(movieManager.movies[1].genres, equals(updatedMovie.genres));
      expect(movieManager.movies[1].bookmarked, equals(false));
    });

    test('addMovies should sort movies by their release dates', () {
      final movies = [
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals([...movies.reversed]));
    });

    test(
        'addMovies should sort movies that have a less precise release date before movies with more precise release dates',
        () {
      final movies = [
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.month,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      expect(movieManager.movies, equals([...movies.reversed]));
    });

    test(
        'when a movie is modified and it\'s date is changed the movies should be resorted',
        () async {
      final movies = [
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(1998, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
      ];

      movieManager.addMovies(movies);

      final movie = movieManager.movies.first;
      movie.setDetails(
        releaseDate: DateWithPrecisionAndCountry(DateTime(2003, 5, 7),
            DatePrecision.day, 'United States of America'),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(movieManager.movies, equals([...movies.reversed]));
    });

    test('removeMoviesWhere should remove movies from the list', () {
      final movies = [
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
      ];
      MovieData notRemoved = MovieData(
        'Harry Potter and the Philosopher\'s Stone',
        DateWithPrecisionAndCountry(
            DateTime(2001, 11, 4), DatePrecision.day, 'United Kingdom'),
      );

      movieManager.addMovies([...movies, notRemoved]);

      movieManager.removeMoviesWhere((movie) => movie.title.contains('Matrix'));

      expect(movieManager.movies, equals([notRemoved]));
    });

    test("localSearch", () {
      final movies = [
        MovieData(
          'The Matrix',
          DateWithPrecisionAndCountry(DateTime(1999, 3, 31), DatePrecision.day,
              'United States of America'),
        ),
        MovieData(
          'The Matrix Reloaded',
          DateWithPrecisionAndCountry(DateTime(2003, 5, 7), DatePrecision.day,
              'United States of America'),
        ),
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
