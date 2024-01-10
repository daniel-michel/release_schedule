import 'dart:async';

import 'package:flutter/material.dart';
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

  void _moviesModified({bool withoutAddingOrRemoving = false}) {
    cacheUpdater.call();
    if (!withoutAddingOrRemoving) {
      // only notify listeners if movies are added or removed
      // if they are modified in place they will notify listeners themselves
      notifyListeners();
    }
  }

  List<MovieData> addMovies(List<MovieData> additionalMovies) {
    List<MovieData> actualMovies = [];
    bool added = false;
    for (var movie in additionalMovies) {
      MovieData? existing =
          movies.where((element) => movie.same(element)).firstOrNull;
      if (existing == null) {
        _insertMovie(movie);
        movie.addListener(() {
          _moviesModified(withoutAddingOrRemoving: true);
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
    for (int i = 0; i < movies.length; i++) {
      var temp = movies[i];
      DateWithPrecision? tempDate = temp.releaseDate?.dateWithPrecision;
      int j = i - 1;
      for (; j >= 0; j--) {
        DateWithPrecision? date = movies[j].releaseDate?.dateWithPrecision;
        if (date == null || tempDate != null && date.compareTo(tempDate) <= 0) {
          break;
        }
        movies[j + 1] = movies[j];
      }
      movies[j + 1] = temp;
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
            ]);
    return results;
  }

  /// Online search for movies.
  Future<List<MovieData>> onlineSearch(String search) async {
    List<MovieData> movies = await api.searchForMovies(search);
    return addMovies(movies);
  }

  Future<void> loadUpcomingMovies() async {
    try {
      loading = true;
      notifyListeners();
      List<MovieData> movies = await api
          .getUpcomingMovies(DateTime.now().subtract(const Duration(days: 7)));
      addMovies(movies);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
