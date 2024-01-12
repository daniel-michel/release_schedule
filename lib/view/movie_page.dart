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
          appBar: AppBar(title: Text(movie.title ?? "-"), actions: [
            IconButton(
              icon: Icon(movie.bookmarked
                  ? Icons.bookmark_added
                  : Icons.bookmark_outline),
              onPressed: () => movie.setDetails(bookmarked: !movie.bookmarked),
            ),
          ]),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: movie.genres?.value
                            ?.map((genre) => Chip(label: Text(genre)))
                            .toList() ??
                        [],
                  ),
                  const Heading("About"),
                  Text(
                    movie.description?.value?.trim().replaceAll("\n", "\n\n") ??
                        "-",
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                  const Heading("Titles"),
                  Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    children: movie.titles?.value?.map((title) {
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
                                child: Text(title.text),
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
                    children: movie.releaseDates?.value?.map((releaseDate) {
                          return TableRow(
                            children: [
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(releaseDate.place),
                              )),
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  releaseDate.dateWithPrecision.toString(),
                                ),
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
