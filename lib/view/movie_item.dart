import 'package:flutter/material.dart';
import 'package:release_schedule/model/date_format.dart';
import 'package:release_schedule/model/movie.dart';

class MovieItem extends StatelessWidget {
  final MovieData movie;
  const MovieItem(this.movie, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: movie,
      builder: (context, widget) {
        return ListTile(
            title: Text(movie.title),
            subtitle: Text(
                "${dateRelativeToNow(movie.releaseDate.date)}, ${movie.releaseDate.toString()}, ${movie.genres?.join(", ") ?? ""}"));
      },
    );
  }
}
