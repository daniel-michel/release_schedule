import 'package:flutter/material.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MovieList extends StatelessWidget {
  final List<MovieData> movies;
  final bool Function(MovieData)? filter;
  const MovieList(this.movies, {this.filter, super.key});

  @override
  Widget build(BuildContext context) {
    Widget noMovies() {
      return Center(
        child: IntrinsicHeight(
          child: Column(
            children: [
              const Icon(
                Icons.close,
                size: 100,
              ),
              Text(
                "No Movies",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (movies.isEmpty) {
      return noMovies();
    }

    Widget buildGroupSeparator(BuildContext context, DateWithPrecision date) {
      bool highlight = date.includes(DateTime.now());
      return SizedBox(
        height: 50,
        child: Align(
          alignment: Alignment.center,
          child: Card(
            elevation: 3,
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
      if (indexMap.isEmpty) {
        return noMovies();
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
      return GroupedList<DateWithPrecision>(
        itemCount: indexMap.length,
        groupBy: (index) =>
            movies[indexMap[index]].releaseDate.dateWithPrecision,
        groupSeparatorBuilder: (date) => buildGroupSeparator(context, date),
        itemBuilder: (context, index) {
          return MovieItem(movies[indexMap[index]]);
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
    return GroupedList<DateWithPrecision>(
      itemCount: movies.length,
      groupBy: (index) => movies[index].releaseDate.dateWithPrecision,
      groupSeparatorBuilder: (date) => buildGroupSeparator(context, date),
      itemBuilder: (context, index) {
        return MovieItem(movies[index]);
      },
      initialScrollIndex: firstMovieTodayOrAfterIndex,
    );
  }
}

class GroupedList<GroupType> extends StatelessWidget {
  final int itemCount;
  final int initialScrollIndex;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(GroupType) groupSeparatorBuilder;
  final GroupType Function(int) groupBy;

  const GroupedList(
      {required this.itemCount,
      required this.itemBuilder,
      required this.groupSeparatorBuilder,
      required this.groupBy,
      this.initialScrollIndex = 0,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return Container();
    }
    List<({int index, GroupType group})> newGroupStarts = [
      (index: 0, group: groupBy(0))
    ];
    int internalInitialScrollIndex = initialScrollIndex + 1;
    GroupType last = newGroupStarts[0].group;
    for (int i = 1; i < itemCount; i++) {
      final GroupType current = groupBy(i);
      if (current != last) {
        newGroupStarts.add((index: i, group: current));
        if (initialScrollIndex > i) {
          internalInitialScrollIndex++;
        }
      }
      last = current;
    }

    Widget itemAndSeparatorBuilder(BuildContext context, int index) {
      int itemIndex = index;
      for (int i = 0; i < newGroupStarts.length; i++) {
        if (newGroupStarts[i].index > itemIndex) {
          break;
        } else if (newGroupStarts[i].index == itemIndex) {
          return groupSeparatorBuilder(groupBy(itemIndex));
        }
        itemIndex--;
      }
      return itemBuilder(context, itemIndex);
    }

    return ScrollablePositionedList.builder(
      itemCount: itemCount + newGroupStarts.length,
      itemBuilder: itemAndSeparatorBuilder,
      initialScrollIndex: internalInitialScrollIndex,
    );
  }
}
