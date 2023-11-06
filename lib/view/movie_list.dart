import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';

class MovieList extends StatelessWidget {
  final List<MovieData> movies;
  const MovieList(this.movies, {super.key});

  @override
  Widget build(Object context) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieItem(movies[index]);
      },
    );
  }
}
