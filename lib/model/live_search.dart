import 'package:flutter/material.dart';
import 'package:release_schedule/model/delayed_function_caller.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';

class LiveSearch extends ChangeNotifier {
  String searchTerm = "";
  List<MovieData> searchResults = [];
  late final DelayedFunctionCaller _searchCaller;
  final MovieManager manager;
  bool searchingOnline = false;

  LiveSearch(this.manager) {
    _searchCaller = DelayedFunctionCaller(
      searchOnline,
      const Duration(milliseconds: 750),
      resetTimerOnCall: true,
    );
  }

  get loading => searchingOnline || _searchCaller.scheduled;

  void updateSearch(String search) async {
    searchTerm = search;
    if (searchTerm.isEmpty) {
      return;
    }
    _searchCaller.call();
    notifyListeners();
    var localResults = await manager.localSearchAsync(search);
    if (searchTerm != search) return;
    searchResults = localResults;
    notifyListeners();
  }

  void searchOnline() async {
    if (searchTerm.isEmpty) {
      return;
    }
    if (searchingOnline) {
      _searchCaller.call();
      notifyListeners();
      return;
    }
    searchingOnline = true;
    try {
      String startedSearching = searchTerm;
      List<MovieData> onlineResults = await manager.onlineSearch(searchTerm);
      searchingOnline = false;
      // if the search term has changed since we started searching, ignore the results
      if (startedSearching != searchTerm) return;
      List<MovieData> localResults = await manager.localSearchAsync(searchTerm);
      if (startedSearching != searchTerm) return;

      localResults.removeWhere((element) => onlineResults.contains(element));
      searchResults = onlineResults + localResults;
      notifyListeners();
    } finally {
      searchingOnline = false;
      notifyListeners();
    }
  }
}
