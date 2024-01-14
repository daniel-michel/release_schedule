import 'dart:math';

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
    double width = MediaQuery.of(context).size.width;
    double gap = min(width / 50, 10);
    double padding = min(width / 20, 15);
    double space = width - gap * 3 - padding * 2;
    double posterWidth = min(space / 5, 70);
    double bookmarkWidth = 50;
    double mainSectionWidth = space - posterWidth - bookmarkWidth;
    return AnimatedBuilder(
      animation: movie,
      builder: (context, widget) {
        return ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: padding, vertical: padding - 5),
          title: Padding(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: posterWidth,
                  child: movie.poster != null
                      ? Hero(
                          tag: movie.poster ?? "",
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image(
                              image: movie.poster!,
                              width: posterWidth,
                            ),
                          ),
                        )
                      : const Icon(Icons.movie),
                ),
                SizedBox(
                  width: mainSectionWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title ?? "-",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      showReleaseDate || movie.genres?.value != null
                          ? Text(
                              (showReleaseDate
                                      ? "${movie.releaseDate ?? "release date unknown"}"
                                      : "") +
                                  (showReleaseDate &&
                                          movie.genres?.value != null
                                      ? " - "
                                      : "") +
                                  (movie.genres?.value?.join(", ") ?? ""),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
                // SizedBox(
                //   width: bookmarkWidth,
                //   child:
                // ),
              ],
            ),
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
