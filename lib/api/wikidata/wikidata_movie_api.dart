import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:release_schedule/api/api_manager.dart';
import 'package:release_schedule/api/json_helper.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';

class WikidataProperties {
  static const String instanceOf = "P31";
  static const String publicationDate = "P577";
  static const String title = "P1476";
  static const String partOfTheSeries = "P179";
  static const String basedOn = "P144";
  static const String derivativeWork = "P4969";
  static const String genre = "P136";
  static const String countryOfOrigin = "P496";
  static const String director = "P57";
  static const String castMember = "P161";
  static const String distributedBy = "P750";
  static const String afterAWorkBy = "P1877";
  static const String duration = "P2047";
  static const String reviewScore = "P444";
  static const String fskFilmRating = "P1981";
  static const String placeOfPublication = "P291";
  static const String shortName = "P1813";
  static const String imdbId = "P345";
}

class WikidataEntities {
  static const String film = "Q11424";
  static const String filmProject = "Q18011172";
  static const String featureFilm = "Q24869";
  static const String filmReboot = "Q111241092";
  static const String animatedFilm = "Q202866";
  static const String animatedFeatureFilm = "Q29168811";
  static const String animatedFilmReboot = "Q118189123";
  static const String computerAnimatedFilm = "Q28968258";
  static const String threeDFilm = "Q229390";
  static const String filmAdaption = "Q1257444";
  static const String tvSeries = "Q5398426";
}

const filmTypeEntities = [
  WikidataEntities.film,
  WikidataEntities.filmProject,
  WikidataEntities.featureFilm,
  WikidataEntities.filmReboot,
  WikidataEntities.animatedFilm,
  WikidataEntities.animatedFeatureFilm,
  WikidataEntities.threeDFilm,
  WikidataEntities.computerAnimatedFilm,
  WikidataEntities.animatedFilmReboot,
  WikidataEntities.filmAdaption,
];

ApiManager _wikidataApi =
    ApiManager("https://www.wikidata.org/w/api.php?origin=*");
ApiManager _queryApi =
    ApiManager("https://query.wikidata.org/sparql?format=json&origin=*");

class WikidataMovieApi implements MovieApi {
  @override
  Future<Iterable<WikidataMovieData>> getUpcomingMovies(DateTime startDate,
      [int count = 100]) async {
    Response filmResponse = await _queryApi.get(
        "&query=${Uri.encodeComponent(_createUpcomingMovieQuery(startDate, WikidataEntities.film, count))}");
    Response filmProjectResponse = await _queryApi.get(
        "&query=${Uri.encodeComponent(_createUpcomingMovieQuery(startDate, WikidataEntities.filmProject, count))}");
    List<Response> responses = [filmResponse, filmProjectResponse];
    for (var response in responses) {
      if (response.statusCode != 200) {
        throw Exception(
            "The Wikidata request for upcoming movies failed with status ${response.statusCode} ${response.reasonPhrase}");
      }
    }
    Iterable<Map<String, dynamic>> results =
        responses.map((response) => jsonDecode(response.body));
    Iterable<dynamic> entries =
        results.expand((result) => result["results"]["bindings"]);
    return entries.map((entry) {
      final entityId =
          RegExp(r"Q\d+$").firstMatch(entry["movie"]["value"])![0]!;
      final releaseDate = DateTime.parse(entry["minReleaseDate"]["value"]);
      final String label = entry["movieLabel"]["value"];
      final movie = WikidataMovieData(entityId);
      movie.setDetails(
        releaseDates: Dated.outdated(
          [DateWithPrecisionAndPlace(releaseDate, DatePrecision.day, null)],
        ),
      );
      if (!RegExp(r"^Q\d+$").hasMatch(label)) {
        movie.setDetails(
          labels: Dated.outdated([(text: label, language: "en")]),
        );
      }
      return movie;
    });
  }

  @override
  Future<List<WikidataMovieData>> searchForMovies(String searchTerm) async {
    var instanceOfQuery = filmTypeEntities
        .map((entity) => "${WikidataProperties.instanceOf}=$entity")
        .join("|");
    String haswbstatement = "haswbstatement:$instanceOfQuery";
    String encodedSearchTerm = Uri.encodeComponent(searchTerm);
    String query =
        "&action=query&list=search&format=json&srsearch=$encodedSearchTerm%20$haswbstatement";
    Response result = await _wikidataApi.get(query);
    Map<String, dynamic> json = jsonDecode(result.body);
    List<Map<String, dynamic>> searchResults =
        selectInJson<Map<String, dynamic>>(json, "query.search.*").toList();
    List<String> ids = searchResults
        .map((result) => result["title"] as String)
        .where((title) => RegExp(r"^Q\d+$").hasMatch(title))
        .toList();
    return ids.map((id) => WikidataMovieData(id)).toList();
  }

  @override
  Future<void> updateMovies(
    List<MovieData> movies,
    InformationFidelity fidelity,
  ) async {
    final List<WikidataMovieData> wikidataMovies =
        movies.cast<WikidataMovieData>();
    {
      // primary data
      final List<WikidataMovieData> moviesToUpdate = wikidataMovies
          .where((movie) => shouldUpdateForMovie(
                [
                  movie.labels,
                  movie.titles,
                  movie.releaseDatesWithPlaceId,
                  movie.genreIds,
                  movie.wikipediaTitle,
                ],
                movie,
                aggressive: fidelity == InformationFidelity.details,
              ))
          .toList();
      if (moviesToUpdate.isNotEmpty) {
        try {
          for (final movie in moviesToUpdate) {
            movie.setLoading(true);
          }
          await _updateMoviePrimaryData(moviesToUpdate);
        } finally {
          for (final movie in moviesToUpdate) {
            movie.setLoading(false);
          }
        }
      }
    }
    if (fidelity == InformationFidelity.upcoming ||
        fidelity == InformationFidelity.details) {
      // entity labels
      final List<WikidataMovieData> moviesToUpdate = wikidataMovies
          .where((movie) => shouldUpdateForMovie(
                [
                  movie.genres,
                  movie.releaseDates,
                ],
                movie,
                aggressive: fidelity == InformationFidelity.details,
              ))
          .toList();
      if (moviesToUpdate.isNotEmpty) {
        try {
          for (final movie in moviesToUpdate) {
            movie.setLoading(true);
          }
          await _updateEntityLabels(moviesToUpdate);
        } finally {
          for (final movie in moviesToUpdate) {
            movie.setLoading(false);
          }
        }
      }
    }
    if (fidelity == InformationFidelity.details ||
        fidelity == InformationFidelity.upcoming ||
        fidelity == InformationFidelity.search) {
      // wikipedia intro text
      final List<WikidataMovieData> moviesToUpdate = wikidataMovies
          .where((movie) => shouldUpdateForMovie(
                [movie.description],
                movie,
                aggressive: fidelity == InformationFidelity.details,
              ))
          .toList();
      if (moviesToUpdate.isNotEmpty) {
        try {
          for (final movie in moviesToUpdate) {
            movie.setLoading(true);
          }
          await _updateDescriptionUsingWikipediaIntroText(moviesToUpdate);
        } finally {
          for (final movie in moviesToUpdate) {
            movie.setLoading(false);
          }
        }
      }
    }
  }
}

Future<void> _updateMoviePrimaryData(List<WikidataMovieData> movies) async {
  const batchSize = 50;
  Map<String, dynamic> entities = {};
  for (int i = 0; i < (movies.length / batchSize).ceil(); i++) {
    final start = i * batchSize;
    final end = min((i + 1) * batchSize, movies.length);
    final String ids =
        movies.sublist(start, end).map((movie) => movie.entityId).join("|");
    var response = await _wikidataApi.get(
        "&action=wbgetentities&format=json&props=labels|claims|sitelinks&ids=$ids");
    Map<String, dynamic> result = jsonDecode(response.body);
    Map<String, dynamic> batchEntities = result["entities"];
    entities.addAll(batchEntities);
  }
  for (final movie in movies) {
    final entity = entities[movie.entityId];
    movie.updateWithWikidataEntity(entity);
  }
}

Future<void> _updateEntityLabels(List<WikidataMovieData> movies) async {
  List<String> allCountryAndGenreIds = [];
  // Add the country ids from the publication dates
  allCountryAndGenreIds.addAll(movies.expand((movie) =>
      movie.releaseDatesWithPlaceId?.value
          ?.map((release) => release.place)
          .whereType<String>() ??
      []));
  // Add the genre ids
  allCountryAndGenreIds
      .addAll(movies.expand((movie) => movie.genreIds?.value ?? []));
  allCountryAndGenreIds = allCountryAndGenreIds.toSet().toList();
  // Prefetch all labels for countries and genres
  // to reduce the number of api calls,
  // they will be retrieved from the cache in updateFromCache
  await _getLabelsForEntities(allCountryAndGenreIds);
  for (final movie in movies) {
    movie.updateGenresFromCache();
    movie.updateReleaseDatePlacesFromCache();
  }
}

Future<void> _updateDescriptionUsingWikipediaIntroText(
    List<WikidataMovieData> movies) async {
  Iterable<String> allWikipediaTitles = movies
      .map<String?>((movie) => movie.wikipediaTitle?.value)
      .whereType<String>();
  await _getWikipediaIntroTextAndPageImageForTitles(
      allWikipediaTitles.toList());
  for (final movie in movies) {
    movie.updateWikipediaTitleAndImageFromCache();
  }
}

bool shouldUpdateForMovie(List<Dated?> data, MovieData movie,
    {bool aggressive = false}) {
  if (data.any((data) => data == null)) {
    return true;
  }
  Duration maxAge =
      aggressive ? const Duration(hours: 2) : maxAgeForMovie(movie);
  return data.any((data) => data?.isOutdated(maxAge) ?? true);
}

Duration maxAgeForMovie(MovieData movie) {
  var releaseDate = movie.releaseDate;
  if (releaseDate == null) {
    return const Duration(days: 3);
  }
  Duration difference = releaseDate.date.difference(DateTime.now());
  int inDays = difference.inDays;
  if (inDays > 30) {
    return const Duration(days: 14);
  } else if (inDays > -14) {
    return const Duration(days: 1);
  } else if (inDays > -365) {
    return const Duration(days: 30);
  }
  return const Duration(days: 365);
}

String _createUpcomingMovieQuery(
    DateTime startDate, String instanceOf, int limit) {
  String date = DateFormat("yyyy-MM-dd").format(startDate);
  return """
SELECT
  ?movie
  ?movieLabel
  (MIN(?releaseDate) as ?minReleaseDate)
WHERE {
  ?movie wdt:${WikidataProperties.instanceOf} wd:$instanceOf;
         wdt:${WikidataProperties.publicationDate} ?releaseDate.
  ?movie p:${WikidataProperties.publicationDate}/psv:${WikidataProperties.publicationDate} [wikibase:timePrecision ?precision].
  FILTER (xsd:date(?releaseDate) >= xsd:date("$date"^^xsd:dateTime))
  FILTER (?precision >= 10)

  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
GROUP BY ?movie ?movieLabel
ORDER BY ?minReleaseDate
LIMIT $limit""";
}

DatePrecision precisionFromWikidata(int precision) {
  return switch (precision) {
    >= 13 => DatePrecision.minute,
    12 => DatePrecision.hour,
    11 => DatePrecision.day,
    10 => DatePrecision.month,
    9 => DatePrecision.year,
    8 => DatePrecision.decade,
    < 8 => throw Exception("The precision was too low, value: $precision"),
    _ => throw Exception("Unexpected precision value: $precision"),
  };
}

Map<String, String> _labelCache = {};
Future<Map<String, String>> _getLabelsForEntities(
    List<String> entityIds) async {
  assert(entityIds.every((id) => RegExp(r"^Q\d+$").hasMatch(id)),
      "The entity ids must be valid Wikidata ids");
  const batchSize = 50;
  Map<String, String> labels = {};
  for (int i = entityIds.length - 1; i >= 0; i--) {
    if (_labelCache.containsKey(entityIds[i])) {
      labels[entityIds[i]] = _labelCache[entityIds[i]]!;
      entityIds.removeAt(i);
    }
  }
  for (int i = 0; i < (entityIds.length / batchSize).ceil(); i++) {
    final start = i * batchSize;
    final end = min((i + 1) * batchSize, entityIds.length);
    Response response = await _wikidataApi.get(
      "&action=wbgetentities&format=json&props=labels|claims&ids=${entityIds.sublist(start, end).join("|")}",
    );
    if (response.statusCode != 200) {
      throw Exception(
        "The Wikidata request for labels failed with status ${response.statusCode} ${response.reasonPhrase}\n${response.body}",
      );
    }
    Map<String, dynamic> result = jsonDecode(response.body);
    Map<String, dynamic> batchEntities = result["entities"];
    for (String entityId in batchEntities.keys) {
      String? shortName = selectInJson(batchEntities[entityId],
              "claims.${WikidataProperties.shortName}.*.mainsnak.datavalue.value")
          .where((value) => value["language"] == "en")
          .map((value) => (value["text"] as String))
          .firstOrNull;
      Map<String, dynamic> responseLabels = batchEntities[entityId]["labels"];
      if (shortName != null) {
        _labelCache[entityId] = labels[entityId] = shortName;
        continue;
      }
      String label = responseLabels.containsKey("en")
          ? responseLabels["en"]["value"]
          : responseLabels[responseLabels.keys.first]["value"];
      _labelCache[entityId] = labels[entityId] = label;
    }
  }
  return labels;
}

String? getCachedLabelForEntity(String entityId) {
  return _labelCache[entityId];
}

ApiManager _wikipediaApi =
    ApiManager("https://en.wikipedia.org/w/api.php?format=json&origin=*");
typedef WikipediaIntroAndPageImage = ({String? text, String? image});
Map<String, Dated<WikipediaIntroAndPageImage>>
    _wikipediaIntroTextAndImageCache = {};

Future<Map<String, Dated<WikipediaIntroAndPageImage>>>
    _getWikipediaIntroTextAndPageImageForTitles(List<String> pageTitles) async {
  const batchSize = 50;
  Map<String, Dated<WikipediaIntroAndPageImage>> explainTexts = {};
  for (int i = pageTitles.length - 1; i >= 0; i--) {
    if (_wikipediaIntroTextAndImageCache.containsKey(pageTitles[i])) {
      explainTexts[pageTitles[i]] =
          _wikipediaIntroTextAndImageCache[pageTitles[i]]!;
      pageTitles.removeAt(i);
    }
  }
  const maxImageWidth = 300;
  for (int i = 0; i < (pageTitles.length / batchSize).ceil(); i++) {
    final start = i * batchSize;
    final end = min((i + 1) * batchSize, pageTitles.length);
    Response response = await _wikipediaApi.get(
        "&action=query&prop=extracts|pageimages&exintro&explaintext&pithumbsize=$maxImageWidth&pilicense=free&redirects=1&titles=${pageTitles.sublist(start, end).join("|")}");
    Map<String, dynamic> result = jsonDecode(response.body);
    List<dynamic>? normalize = result["query"]["normalized"];
    Map<String, dynamic> batchPages = result["query"]["pages"];
    for (String pageId in batchPages.keys) {
      String pageTitle = batchPages[pageId]["title"];
      String originalTitle = normalize
              ?.where((element) => element["to"] == pageTitle)
              .firstOrNull?["from"] ??
          pageTitle;
      String? introText = batchPages[pageId]["extract"];
      String? imageUrl = batchPages[pageId]["thumbnail"]?["source"];
      _wikipediaIntroTextAndImageCache[originalTitle] =
          explainTexts[originalTitle] =
              Dated.now((text: introText, image: imageUrl));
    }
  }
  return explainTexts;
}

Dated<WikipediaIntroAndPageImage>?
    getCachedWikipediaIntroTextAndPageImageForTitle(String title) {
  return _wikipediaIntroTextAndImageCache[title];
}
