import 'package:flutter/material.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final MovieManager manager;

  const MoviePage({required this.movie, required this.manager, super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      manager.updateMovies([movie], InformationFidelity.details);
    });
    return AnimatedBuilder(
      animation: movie,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: Text(movie.title ?? "-"), actions: [
            movie.loading
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      movie.setOutdated();
                      manager.updateMovies(
                        [movie],
                        InformationFidelity.details,
                      );
                    },
                  ),
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
                    runSpacing: 4,
                    children: movie.genres?.value
                            ?.map((genre) => Chip(label: Text(genre)))
                            .toList() ??
                        [],
                  ),
                  aboutSection(context),
                  titlesSection(context),
                  releaseDatesSection(context),
                  wikidataSection(context),
                ].whereType<Widget>().toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? aboutSection(BuildContext context) {
    if (movie.description?.value == null) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Heading("About"),
        Text(
          movie.description?.value?.trim().replaceAll("\n", "\n\n") ?? "-",
          textAlign: TextAlign.justify,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget? titlesSection(BuildContext context) {
    if (movie.titles?.value?.isEmpty ?? true) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget? releaseDatesSection(BuildContext context) {
    if (movie.releaseDates?.value?.isEmpty ?? true) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Heading("Release Dates"),
        Table(
          border: TableBorder.symmetric(
            inside: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          children: movie.releaseDates?.value?.map(
                (releaseDate) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(releaseDate.place ?? "unknown place"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            releaseDate.dateWithPrecision.toString(),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ).toList() ??
              [],
        ),
      ],
    );
  }

  Widget? wikidataSection(BuildContext context) {
    if (movie is! WikidataMovieData) {
      return null;
    }
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Heading("Wikidata"),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrl(Uri.parse(
                    "https://www.wikidata.org/wiki/${(movie as WikidataMovieData).entityId}",
                  )),
                ),
              ],
            ),
            Text(
              "Entity Id: ${(movie as WikidataMovieData).entityId}",
            ),
          ],
        )
      ],
    );
  }
}
