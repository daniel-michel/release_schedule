import 'dart:async';

import 'package:flutter/material.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata_movie_api.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie.dart';

T? firstWhereOrNull<T>(List<T> list, bool Function(T element) test) {
  try {
    return list.firstWhere(test);
  } catch (e) {
    return null;
  }
}

class DelayedFunctionCaller {
  final Function function;
  final Duration duration;
  Timer? _timer;

  DelayedFunctionCaller(this.function, this.duration);

  void call() {
    // If a timer is already active, return.
    if (_timer != null && _timer!.isActive) {
      return;
    }

    // Create a timer that calls the function after the specified duration.
    _timer = Timer(duration, () {
      function();
    });
  }
}

final movieManager = MovieManager(WikidataMovieApi(),
    LocalMovieStorageGetStorage(WikidataMovieData.fromEncodable));

class MovieManager extends ChangeNotifier {
  final List<MovieData> movies = List.empty(growable: true);
  final LocalMovieStorage cache;
  final MovieApi api;
  bool loading = false;
  DelayedFunctionCaller? cacheUpdater;
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
    cacheUpdater?.call();
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
          firstWhereOrNull(movies, (element) => movie.same(element));
      if (existing == null) {
        _insertMovie(movie);
        movie.addListener(() {
          _moviesModified(withoutAddingOrRemoving: true);
          _resortMovies();
        });
        added = true;
        actualMovies.add(movie);
      } else {
        existing.updateWithNew(movie);
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
    while (min - 1 < max) {
      int center = ((min + max) / 2).floor();
      int diff =
          movie.releaseDate.date.compareTo(movies[center].releaseDate.date);
      if (diff < 0) {
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
      int j = i - 1;
      for (;
          j >= 0 && movies[j].releaseDate.date.isAfter(temp.releaseDate.date);
          j--) {
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
  localSearch(String search) {}

  /// Online search for movies.
  Future<List<MovieData>> search(String search) async {
    List<MovieData> movies = await api.searchForMovies(search);
    return addMovies(movies);
  }

  void expandDetails(List<MovieData> movies) {
    api.addMovieDetails(movies);
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

class LiveSearch<CustomMovieData extends MovieData> extends ChangeNotifier {
  String searchTerm = "";
  List<CustomMovieData> searchResults = [];
  Duration minTimeBetweenRequests = const Duration(milliseconds: 500);
  Duration minTimeAfterChangeToRequest = const Duration(milliseconds: 200);
  final MovieManager manager;

  LiveSearch(this.manager);

  void updateSearch(String search) {
    searchTerm = search;
  }
}
