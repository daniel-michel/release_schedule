import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:release_schedule/api/api_manager.dart';
import 'package:release_schedule/api/json_helper.dart';
import 'package:release_schedule/api/movie_api.dart';
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
}

ApiManager _wikidataApi =
    ApiManager("https://www.wikidata.org/w/api.php?origin=*");

class WikidataMovieApi implements MovieApi {
  ApiManager queryApi =
      ApiManager("https://query.wikidata.org/sparql?format=json&origin=*");

  @override
  Future<void> addMovieDetails(List<MovieData> movies) {
    // TODO: implement addMovieDetails
    throw UnimplementedError();
  }

  @override
  Future<List<WikidataMovieData>> getUpcomingMovies(DateTime startDate,
      [int count = 100]) async {
    Response response = await queryApi.get(
        "&query=${Uri.encodeComponent(_createUpcomingMovieQuery(startDate, count))}");
    if (response.statusCode != 200) {
      throw Exception(
          "The Wikidata request for upcoming movies failed with status ${response.statusCode} ${response.reasonPhrase}");
    }
    Map<String, dynamic> result = jsonDecode(response.body);
    List<dynamic> entries = result["results"]["bindings"];
    List<String> ids = entries
        .map((entry) =>
            RegExp(r"Q\d+$").firstMatch(entry["movie"]["value"])![0]!)
        .toList();
    return _getMovieDataFromIds(ids);
  }

  Future<List<WikidataMovieData>> _getMovieDataFromIds(
      List<String> movieIds) async {
    // Wikidata limits the number of entities per request to 50
    const batchSize = 50;
    Map<String, dynamic> entities = {};
    for (int i = 0; i < (movieIds.length / batchSize).ceil(); i++) {
      final start = i * batchSize;
      final end = min((i + 1) * batchSize, movieIds.length);
      var response = await _wikidataApi.get(
          "&action=wbgetentities&format=json&props=labels|claims&ids=${movieIds.sublist(start, end).join("|")}");
      Map<String, dynamic> result = jsonDecode(response.body);
      Map<String, dynamic> batchEntities = result["entities"];
      entities.addAll(batchEntities);
    }

    List<String> allCountryAndGenreIds = [];
    // Add the country ids from the publication dates
    allCountryAndGenreIds.addAll(selectInJson<String>(entities,
        "*.claims.${WikidataProperties.publicationDate}.*.qualifiers.${WikidataProperties.placeOfPublication}.*.datavalue.value.id"));
    // Add the genre ids
    allCountryAndGenreIds.addAll(selectInJson<String>(entities,
        "*.claims.${WikidataProperties.genre}.*.mainsnak.datavalue.value.id"));
    allCountryAndGenreIds = allCountryAndGenreIds.toSet().toList();
    // Prefetch all labels for countries and genres
    // to reduce the number of api calls,
    // they will be retrieved from the cache in fromWikidataEntity
    await _getLabelsForEntities(allCountryAndGenreIds);

    return movieIds
        .map((id) => WikidataMovieData.fromWikidataEntity(id, entities[id]))
        .toList();
  }

  @override
  Future<List<WikidataMovieData>> searchForMovies(String searchTerm) {
    // TODO: implement searchForMovies
    throw UnimplementedError();
  }
}

class WikidataMovieData extends MovieData {
  String entityId;
  WikidataMovieData(
      String title, DateWithPrecisionAndCountry releaseDate, this.entityId)
      : super(title, releaseDate);

  WikidataMovieData.fromEncodable(Map encodable)
      : entityId = encodable["entityId"],
        super.fromJsonEncodable(encodable);

  @override
  bool same(MovieData other) {
    return other is WikidataMovieData && entityId == other.entityId;
  }

  @override
  Map toJsonEncodable() {
    return super.toJsonEncodable()..addAll({"entityId": entityId});
  }

  static WikidataMovieData fromWikidataEntity(
      String entityId, Map<String, dynamic> entity) {
    String title =
        selectInJson<String>(entity, "labels.en.value").firstOrNull ??
            selectInJson<String>(entity, "labels.*.value").first;
    Map<String, dynamic> claims = entity["claims"];
    List<TitleInLanguage>? titles = selectInJson(
            claims, "${WikidataProperties.title}.*.mainsnak.datavalue.value")
        .map((value) => (
              title: value["text"],
              language: value["language"],
            ) as TitleInLanguage)
        .toList();
    List<DateWithPrecisionAndCountry> releaseDates =
        selectInJson(claims, "${WikidataProperties.publicationDate}.*")
            .map<DateWithPrecisionAndCountry>((dateClaim) {
      var value = selectInJson(dateClaim, "mainsnak.datavalue.value").first;
      String country = _getCachedLabelForEntity(selectInJson<String>(dateClaim,
                  "qualifiers.${WikidataProperties.placeOfPublication}.*.datavalue.value.id")
              .firstOrNull ??
          "unknown location");
      return DateWithPrecisionAndCountry(DateTime.parse(value["time"]),
          _precisionFromWikidata(value["precision"]), country);
    }).toList();
    // Sort release dates with higher precision to the beginning
    releaseDates
        .sort((a, b) => -a.precision.index.compareTo(b.precision.index));
    List<String>? genres = selectInJson<String>(
            claims, "${WikidataProperties.genre}.*.mainsnak.datavalue.value.id")
        .map(_getCachedLabelForEntity)
        .toList();
    WikidataMovieData movie =
        WikidataMovieData(title, releaseDates[0], entityId);
    movie.setDetails(
      titles: titles,
      releaseDates: releaseDates,
      genres: genres,
    );
    return movie;
  }
}

String _createUpcomingMovieQuery(DateTime startDate, int limit) {
  String date = DateFormat("yyyy-MM-dd").format(startDate);
  return """
SELECT
  ?movie
  (MIN(?releaseDate) as ?minReleaseDate)
WHERE {
  ?movie wdt:P31 wd:Q11424;         # Q11424 is the item for "film"
         wdt:P577 ?releaseDate.      # P577 is the "publication date" property
  ?movie p:P577/psv:P577 [wikibase:timePrecision ?precision].
  FILTER (xsd:date(?releaseDate) >= xsd:date("$date"^^xsd:dateTime) && ?precision >= 10)
}
GROUP BY ?movie
ORDER BY ?minReleaseDate
LIMIT $limit""";
}

DatePrecision _precisionFromWikidata(int precision) {
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
        "&action=wbgetentities&format=json&props=labels&ids=${entityIds.sublist(start, end).join("|")}");
    Map<String, dynamic> result = jsonDecode(response.body);
    Map<String, dynamic> batchEntities = result["entities"];
    for (String entityId in batchEntities.keys) {
      Map<String, dynamic> labels = batchEntities[entityId]["labels"];
      String label = labels.containsKey("en")
          ? labels["en"]["value"]
          : labels[labels.keys.first]["value"];
      labels[entityId] = label;
      _labelCache[entityId] = label;
    }
  }
  return labels;
}

String _getCachedLabelForEntity(String entityId) {
  return _labelCache[entityId] ?? entityId;
}
