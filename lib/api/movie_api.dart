import 'package:release_schedule/model/movie.dart';

enum InformationFidelity {
  search,
  upcoming,
  details,
}

class MovieApi {
  Future<Iterable<MovieData>> getUpcomingMovies(DateTime startDate,
          [int count = 10]) async =>
      [];

  Future<Iterable<MovieData>> searchForMovies(String searchTerm) async => [];

  Future<void> updateMovies(
          List<MovieData> movies, InformationFidelity fidelity) async =>
      movies;
}
