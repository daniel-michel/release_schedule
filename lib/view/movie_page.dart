import 'package:flutter/material.dart';
import 'package:release_schedule/model/movie.dart';

class Heading extends StatelessWidget {
  final String text;

  const Heading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class MoviePage extends StatelessWidget {
  final MovieData movie;

  const MoviePage(this.movie, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: movie,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: Text(movie.title), actions: [
            IconButton(
              icon: Icon(movie.bookmarked
                  ? Icons.bookmark_added
                  : Icons.bookmark_outline),
              onPressed: () => movie.setDetails(bookmarked: !movie.bookmarked),
            ),
          ]),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: movie.genres
                            ?.map((genre) => Chip(label: Text(genre)))
                            .toList() ??
                        [],
                  ),
                  const SizedBox(height: 20),
                  const Heading("Titles"),
                  Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    children: movie.titles?.map((title) {
                          return TableRow(
                            children: [
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(title.language),
                              )),
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(title.title),
                              ))
                            ],
                          );
                        }).toList() ??
                        [],
                  ),
                  const Heading("Release Dates"),
                  Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    children: movie.releaseDates?.map((releaseDate) {
                          return TableRow(
                            children: [
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(releaseDate.country),
                              )),
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(releaseDate.toDateString()),
                              ))
                            ],
                          );
                        }).toList() ??
                        [],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
