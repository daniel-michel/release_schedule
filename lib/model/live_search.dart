import 'package:flutter/material.dart';
import 'package:release_schedule/model/delayed_function_caller.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';

class LiveSearch extends ChangeNotifier {
  String searchTerm = "";
  List<MovieData> searchResults = [];
  Duration minTimeBetweenRequests = const Duration(milliseconds: 200);
  late final DelayedFunctionCaller _searchCaller;
  final MovieManager manager;
  bool loading = false;
  bool searchingOnline = false;

  LiveSearch(this.manager) {
    _searchCaller = DelayedFunctionCaller(searchOnline, minTimeBetweenRequests);
  }

  void updateSearch(String search) {
    searchTerm = search;
    if (searchTerm.isEmpty) {
      return;
    }
    searchResults = manager.localSearch(search);
    loading = true;
    _searchCaller.call();
    notifyListeners();
  }

  void searchOnline() async {
    if (searchTerm.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }
    if (searchingOnline) {
      loading = true;
      _searchCaller.call();
      notifyListeners();
      return;
    }
    searchingOnline = true;
    try {
      String startedSearching = searchTerm;
      List<MovieData> onlineResults =
          await movieManager.onlineSearch(searchTerm);
      searchingOnline = false;
      // if the search term has changed since we started searching, ignore the results
      if (startedSearching != searchTerm) {
        return;
      }
      List<MovieData> localResults = manager.localSearch(searchTerm);
      localResults.removeWhere((element) => onlineResults.contains(element));
      searchResults = onlineResults + localResults;
      notifyListeners();
    } finally {
      searchingOnline = false;
      loading = false;
      notifyListeners();
    }
  }
}
