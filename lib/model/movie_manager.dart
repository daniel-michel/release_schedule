import 'package:flutter/material.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata_movie_api.dart';
import 'package:release_schedule/model/movie.dart';

T? firstWhereOrNull<T>(List<T> list, bool Function(T element) test) {
  try {
    return list.firstWhere(test);
  } catch (e) {
    return null;
  }
}

final movieManager = MovieManager(WikidataMovieApi());

class MovieManager<CustomMovieData extends MovieData> extends ChangeNotifier {
  final List<CustomMovieData> movies = List.empty(growable: true);
  final MovieApi<CustomMovieData> api;

  MovieManager(this.api);

  List<CustomMovieData> addMovies(List<CustomMovieData> additionalMovies) {
    List<CustomMovieData> actualMovies = [];
    bool added = false;
    for (var movie in additionalMovies) {
      CustomMovieData? existing =
          firstWhereOrNull(movies, (element) => movie.same(element));
      if (existing == null) {
        movies.add(movie);
        added = true;
        actualMovies.add(movie);
      } else {
        actualMovies.add(existing);
      }
    }
    if (added) {
      notifyListeners();
    }
    return actualMovies;
  }

  /// Only search locally cached movies.
  localSearch(String search) {}

  /// Online search for movies.
  Future<List<CustomMovieData>> search(String search) async {
    List<CustomMovieData> movies = await api.searchForMovies(search);
    return addMovies(movies);
  }

  expandDetails(List<CustomMovieData> movies) {
    api.addMovieDetails(movies);
  }

  loadUpcomingMovies() async {
    List<CustomMovieData> movies = await api.getUpcomingMovies();
    addMovies(movies);
  }
}

class LiveSearch<CustomMovieData extends MovieData> extends ChangeNotifier {
  String searchTerm = "";
  List<CustomMovieData> searchResults = [];
  Duration minTimeBetweenRequests = const Duration(milliseconds: 500);
  Duration minTimeAfterChangeToRequest = const Duration(milliseconds: 200);
  final MovieManager manager;

  LiveSearch(this.manager);

  updateSearch(String search) {
    searchTerm = search;
  }
}
