import 'package:release_schedule/model/movie.dart';

abstract class MovieApi {
  Future<List<MovieData>> getUpcomingMovies(DateTime startDate, [int count]);
  Future<List<MovieData>> searchForMovies(String searchTerm);
  Future<void> addMovieDetails(List<MovieData> movies);
}
