import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_page.dart';

class MovieItem extends StatelessWidget {
  final MovieData movie;
  final bool showReleaseDate;
  const MovieItem(this.movie, {this.showReleaseDate = false, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: movie,
      builder: (context, widget) {
        return ListTile(
          title: Text(movie.title),
          subtitle: Text(
            (showReleaseDate ? "${movie.releaseDate} " : "") +
                (movie.genres?.join(", ") ?? ""),
          ),
          trailing: IconButton(
            icon: Icon(movie.bookmarked
                ? Icons.bookmark_added
                : Icons.bookmark_border),
            onPressed: () => movie.setDetails(bookmarked: !movie.bookmarked),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return MoviePage(movie);
                },
              ),
            );
          },
        );
      },
    );
  }
}
