import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_page.dart';

class MovieItem extends StatelessWidget {
  final MovieManager manager;
  final MovieData movie;
  final bool showReleaseDate;
  const MovieItem({
    required this.movie,
    required this.manager,
    this.showReleaseDate = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: movie,
      builder: (context, widget) {
        return ListTile(
          title: Text(movie.title ?? "-"),
          leading: movie.loading ? const CircularProgressIndicator() : null,
          subtitle: showReleaseDate || movie.genres?.value != null
              ? Text(
                  (showReleaseDate
                          ? "${movie.releaseDate ?? "release date unknown"}"
                          : "") +
                      (showReleaseDate && movie.genres?.value != null
                          ? " - "
                          : "") +
                      (movie.genres?.value?.join(", ") ?? ""),
                )
              : null,
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
                  return MoviePage(movie: movie, manager: manager);
                },
              ),
            );
          },
        );
      },
    );
  }
}
