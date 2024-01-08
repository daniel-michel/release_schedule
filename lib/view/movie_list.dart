import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';

class MovieList extends StatelessWidget {
  final List<MovieData> movies;
  final bool Function(MovieData)? filter;
  const MovieList(this.movies, {this.filter, super.key});

  @override
  Widget build(Object context) {
    final localFilter = filter;
    if (localFilter != null) {
      List<int> indexMap = [];
      int index = 0;
      for (var movie in movies) {
        if (localFilter(movie)) {
          indexMap.add(index);
        }
        index++;
      }
      return ListView.builder(
        itemCount: indexMap.length,
        itemBuilder: (context, index) {
          return MovieItem(movies[indexMap[index]]);
        },
      );
    }
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieItem(movies[index]);
      },
    );
  }
}
