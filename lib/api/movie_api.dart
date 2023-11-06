import 'package:release_schedule/model/movie.dart';

abstract class MovieApi<CustomMovieData extends MovieData> {
  Future<List<CustomMovieData>> getUpcomingMovies([int count]);
  Future<List<CustomMovieData>> searchForMovies(String searchTerm);
  Future<void> addMovieDetails(List<CustomMovieData> movies);
}
