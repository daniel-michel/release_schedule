import 'package:flutter/material.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

class MovieList extends StatelessWidget {
  final List<MovieData> movies;
  final bool Function(MovieData)? filter;
  const MovieList(this.movies, {this.filter, super.key});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return Center(
        child: IntrinsicHeight(
          child: Column(
            children: [
              const Icon(
                Icons.close,
                size: 100,
              ),
              Text(
                "No movies available",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      );
    }
    Widget buildGroupSeparator(BuildContext context, DateWithPrecision date) {
      bool highlight = date.includes(DateTime.now());
      return SizedBox(
        height: 50,
        child: Align(
          alignment: Alignment.center,
          child: Card(
            elevation: 5,
            color: highlight
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                date.toString(),
              ),
            ),
          ),
        ),
      );
    }

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
      int firstMovieTodayOrAfterIndex = () {
        DateWithPrecision today = DateWithPrecision.today();
        int min = 0;
        int max = indexMap.length;
        while (min < max) {
          int center = (min + max) ~/ 2;
          DateWithPrecision date =
              movies[indexMap[center]].releaseDate.dateWithPrecision;
          if (date.compareTo(today) < 0) {
            min = center + 1;
          } else {
            max = center;
          }
        }
        return max;
      }();
      return StickyGroupedListView<int, DateWithPrecision>(
        elements: indexMap,
        floatingHeader: true,
        groupBy: (index) => movies[index].releaseDate.dateWithPrecision,
        groupSeparatorBuilder: (index) => buildGroupSeparator(
            context, movies[index].releaseDate.dateWithPrecision),
        itemBuilder: (context, index) {
          return MovieItem(movies[index]);
        },
        initialScrollIndex: firstMovieTodayOrAfterIndex,
      );
    }
    int firstMovieTodayOrAfterIndex = () {
      DateWithPrecision today = DateWithPrecision.today();
      int min = 0;
      int max = movies.length;
      while (min < max) {
        int center = (min + max) ~/ 2;
        DateWithPrecision date = movies[center].releaseDate.dateWithPrecision;
        if (date.compareTo(today) < 0) {
          min = center + 1;
        } else {
          max = center;
        }
      }
      return max;
    }();
    return StickyGroupedListView<MovieData, DateWithPrecision>(
      elements: movies,
      floatingHeader: true,
      groupBy: (movie) => movie.releaseDate.dateWithPrecision,
      groupSeparatorBuilder: (movie) =>
          buildGroupSeparator(context, movie.releaseDate.dateWithPrecision),
      itemBuilder: (context, movie) {
        return MovieItem(movie);
      },
      initialScrollIndex: firstMovieTodayOrAfterIndex,
    );
  }
}
