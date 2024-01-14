import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/delayed_function_caller.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/search.dart';

class MovieManager extends ChangeNotifier {
  final List<MovieData> movies = List.empty(growable: true);
  final LocalMovieStorage cache;
  final MovieApi api;
  bool loading = false;
  late final DelayedFunctionCaller cacheUpdater;
  bool cacheLoaded = false;

  MovieManager(this.api, this.cache) {
    cacheUpdater = DelayedFunctionCaller(() {
      cache.update(movies);
    }, const Duration(seconds: 3));

    _loadCache();
  }

  Future<void> _loadCache() async {
    addMovies(await cache.retrieve());
  }

  void _moviesModified({bool withoutListModification = false}) {
    cacheUpdater.call();
    if (!withoutListModification) {
      // only notify listeners if movies are added, removed or reordered
      // if they are modified in place they will notify listeners themselves
      notifyListeners();
    }
  }

  List<MovieData> addMovies(Iterable<MovieData> additionalMovies) {
    List<MovieData> actualMovies = [];
    bool added = false;
    for (var movie in additionalMovies) {
      MovieData? existing =
          movies.where((element) => movie.same(element)).firstOrNull;
      if (existing == null) {
        _insertMovie(movie);
        movie.addListener(() {
          _moviesModified(withoutListModification: true);
          _resortMovies();
        });
        added = true;
        actualMovies.add(movie);
      } else {
        existing.updateWithNewIgnoringUserControlled(movie);
        actualMovies.add(existing);
      }
    }
    if (added) {
      _moviesModified();
    }
    return actualMovies;
  }

  void _insertMovie(MovieData movie) {
    int min = 0;
    int max = movies.length - 1;
    DateWithPrecision? movieDate = movie.releaseDate?.dateWithPrecision;
    while (min <= max) {
      int center = (min + max) ~/ 2;
      DateWithPrecision? centerDate =
          movies[center].releaseDate?.dateWithPrecision;
      int diff = movieDate != null && centerDate != null
          ? movieDate.compareTo(centerDate)
          : 0;
      if (movieDate == null || centerDate != null && diff < 0) {
        max = center - 1;
      } else {
        min = center + 1;
      }
    }
    movies.insert(min, movie);
  }

  void _resortMovies() {
    bool resort = false;
    for (int i = 0; i < movies.length; i++) {
      var temp = movies[i];
      DateWithPrecision? tempDate = temp.releaseDate?.dateWithPrecision;
      int j = i - 1;
      for (; j >= 0; j--) {
        DateWithPrecision? date = movies[j].releaseDate?.dateWithPrecision;
        if (date == null || tempDate != null && date.compareTo(tempDate) <= 0) {
          break;
        }
        resort = true;
        movies[j + 1] = movies[j];
      }
      movies[j + 1] = temp;
    }
    if (resort) {
      _moviesModified();
    }
  }

  void removeMoviesWhere(bool Function(MovieData movie) test) {
    bool removedMovies = false;
    for (int i = movies.length - 1; i >= 0; i--) {
      bool remove = test(movies[i]);
      if (remove) {
        removedMovies = true;
        movies.removeAt(i);
      }
    }
    if (removedMovies) {
      _moviesModified();
    }
  }

  /// Only search locally cached movies.
  List<MovieData> localSearch(String search) {
    var results = searchList(
      movies,
      search,
      (movie) => [
        movie.title ?? "",
        ...(movie.titles?.value?.map((title) => title.text) ?? []),
      ],
    );
    return results;
  }

  Future<List<MovieData>> localSearchAsync(String search) async {
    List<MovieData> results = await compute(_isolateSearch,
        (movies: movies.map((movie) => movie.copy()).toList(), search: search));
    final originalMovies = results
        .map(
            (result) => movies.where((movie) => result.same(movie)).firstOrNull)
        .whereType<MovieData>()
        .toList();
    return originalMovies;
  }

  /// Online search for movies.
  Future<List<MovieData>> onlineSearch(String search) async {
    Iterable<MovieData> movies = await api.searchForMovies(search);
    List<MovieData> actualMovies = addMovies(movies);
    await api.updateMovies(actualMovies, InformationFidelity.search);
    return actualMovies;
  }

  Future<void> loadUpcomingMovies() async {
    try {
      loading = true;
      notifyListeners();
      Iterable<MovieData> movies = await api
          .getUpcomingMovies(DateTime.now().subtract(const Duration(days: 7)));
      var actualMovies = addMovies(movies);
      await api.updateMovies(actualMovies, InformationFidelity.upcoming);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateMovies(
      List<MovieData> movies, InformationFidelity fidelity) async {
    assert(movies.every((element) => this.movies.contains(element)),
        "Movies must be managed by this manager");
    await api.updateMovies(movies, fidelity);
  }
}

List<MovieData> _isolateSearch(({List<MovieData> movies, String search}) data) {
  return searchList(
    data.movies,
    data.search,
    (movie) => [
      movie.title ?? "",
      ...(movie.titles?.value?.map((title) => title.text) ?? []),
    ],
  );
}
