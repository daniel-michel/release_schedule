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

  _loadCache() async {
    addMovies(await cache.retrieve());
  }

  _moviesModified({bool withoutAddingOrRemoving = false}) {
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
        movies.add(movie);
        movie.addListener(() {
          _moviesModified(withoutAddingOrRemoving: true);
        });
        added = true;
        actualMovies.add(movie);
      } else {
        actualMovies.add(existing);
      }
    }
    if (added) {
      _moviesModified();
    }
    return actualMovies;
  }

  removeMoviesWhere(bool Function(MovieData movie) test) {
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

  expandDetails(List<MovieData> movies) {
    api.addMovieDetails(movies);
  }

  loadUpcomingMovies() async {
    try {
      loading = true;
      notifyListeners();
      List<MovieData> movies = await api.getUpcomingMovies();
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

  updateSearch(String search) {
    searchTerm = search;
  }
}
