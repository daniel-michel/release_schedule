import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_list.dart';

class MovieManagerList extends StatelessWidget {
  final MovieManager manager;
  const MovieManagerList(this.manager, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        return Column(
          children: [
            manager.loading ? const LinearProgressIndicator() : Container(),
            Expanded(child: MovieList(manager.movies))
          ],
        );
      },
    );
  }
}
