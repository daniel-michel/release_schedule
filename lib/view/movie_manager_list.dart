import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_list.dart';

class MovieManagerList extends StatelessWidget {
  final MovieManager manager;
  final bool Function(MovieData)? filter;
  const MovieManagerList(this.manager, {this.filter, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        return Column(
          children: [
            manager.loading ? const LinearProgressIndicator() : Container(),
            Expanded(child: MovieList(manager.movies, filter: filter))
          ],
        );
      },
    );
  }
}
