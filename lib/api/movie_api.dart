import 'package:release_schedule/model/movie.dart';

class MovieApi {
  Future<List<MovieData>> getUpcomingMovies(DateTime startDate,
          [int count = 10]) async =>
      [];

  Future<List<MovieData>> searchForMovies(String searchTerm) async => [];
}
