import 'dart:math';

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
            child: Column(
              children: [
                HeaderWidget(movie),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      aboutSection(context),
                      titlesSection(context),
                      releaseDatesSection(context),
                      moreInformationSection(context),
                    ].whereType<Widget>().toList(),
                  ),
                ),
              ],
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

  Widget? moreInformationSection(BuildContext context) {
    if (movie is! WikidataMovieData) {
      return null;
    }
    WikidataMovieData wikidataMovie = movie as WikidataMovieData;
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Heading("More Information"),
            TextButton(
              child: Text(
                "Wikidata: ${(movie as WikidataMovieData).entityId}",
              ),
              onPressed: () => launchUrl(Uri.parse(
                "https://www.wikidata.org/wiki/${wikidataMovie.entityId}",
              )),
            ),
            wikidataMovie.wikipediaTitle?.value != null
                ? TextButton(
                    child: Text(
                        "Wikipedia: ${wikidataMovie.wikipediaTitle?.value}"),
                    onPressed: () => launchUrl(Uri.parse(
                        "https://en.wikipedia.org/wiki/${Uri.encodeComponent(wikidataMovie.wikipediaTitle?.value ?? "")}")),
                  )
                : const SizedBox(),
            wikidataMovie.imdbId?.value != null
                ? TextButton(
                    child: Text("IMDb: ${wikidataMovie.imdbId?.value}"),
                    onPressed: () => launchUrl(Uri.parse(
                        "https://www.imdb.com/title/${wikidataMovie.imdbId?.value}")),
                  )
                : const SizedBox(),
          ],
        )
      ],
    );
  }
}

class HeaderWidget extends StatelessWidget {
  final MovieData movie;

  const HeaderWidget(this.movie, {super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool titleNextToPoster = width > 500;
    double posterWidth = movie.poster != null
        ? min(titleNextToPoster ? width / 3 : width, 300)
        : 0;
    double posterRadius = titleNextToPoster ? 0 : posterWidth * 0.07;
    double headerTextWidth = titleNextToPoster ? width - posterWidth : width;

    return Flex(
      direction: titleNextToPoster ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: titleNextToPoster
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.center,
      children: [
        movie.poster != null
            ? Hero(
                tag: movie.poster ?? "",
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(posterRadius),
                  child: Image(
                    image: movie.poster!,
                    width: posterWidth,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : null,
        SizedBox(
          width: headerTextWidth,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title ?? "-",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(movie.releaseDate?.dateWithPrecision.toString() ?? "-"),
                const SizedBox(height: 10),
                genreChips(movie),
              ],
            ),
          ),
        ),
      ].whereType<Widget>().toList(),
    );
  }
}

Widget genreChips(MovieData movie) {
  return Wrap(
    spacing: 10,
    runSpacing: 4,
    children: movie.genres?.value
            ?.map((genre) => Chip(label: Text(genre)))
            .toList() ??
        [],
  );
}
