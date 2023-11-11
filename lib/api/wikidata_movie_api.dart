import 'dart:convert';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:release_schedule/api/api_manager.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/movie.dart';

class WikidataMovieData extends MovieData {
  int entityId;
  WikidataMovieData(String title, DateTime releaseDate,
      DatePrecision releaseDatePrecision, this.entityId)
      : super(title, releaseDate, releaseDatePrecision);

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
}

class WikidataMovieApi implements MovieApi {
  ApiManager searchApi = ApiManager("https://www.wikidata.org/w/api.php");
  ApiManager queryApi =
      ApiManager("https://query.wikidata.org/sparql?format=json");

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
    List<WikidataMovieData> movies = [];
    for (Map<String, dynamic> entry in entries) {
      String identifier =
          RegExp(r"Q\d+$").firstMatch(entry["movie"]["value"])![0]!;
      movies.add(WikidataMovieData(
          entry["movieLabel"]["value"] as String,
          DateTime.parse(entry["minReleaseDate"]["value"] as String),
          _precisionFromWikidata(int.parse(entry["datePrecision"]["value"])),
          int.parse(identifier.substring(1))));
    }
    return movies;
  }

  @override
  Future<List<WikidataMovieData>> searchForMovies(String searchTerm) {
    // TODO: implement searchForMovies
    throw UnimplementedError();
  }
}

String _createUpcomingMovieQuery(DateTime startDate, int limit) {
  String date = DateFormat("yyyy-MM-dd").format(startDate);
  return """
SELECT
  ?movie
  ?movieLabel
  (MIN(?releaseDate) as ?minReleaseDate)
  (SAMPLE(?precision) as ?datePrecision)
WHERE {
  ?movie wdt:P31 wd:Q11424;         # Q11424 is the item for "film"
         wdt:P577 ?releaseDate;      # P577 is the "publication date" property
         wdt:P1476 ?title.
  OPTIONAL {
    ?movie p:P577/psv:P577/wikibase:timePrecision ?precision.
  }
  FILTER (xsd:date(?releaseDate) >= xsd:date("$date"^^xsd:dateTime))

  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
GROUP BY ?movie ?movieLabel
ORDER BY ?minReleaseDate
LIMIT $limit""";
}

DatePrecision _precisionFromWikidata(int precision) {
  return switch (precision) {
    >= 11 => DatePrecision.day,
    10 => DatePrecision.month,
    9 => DatePrecision.year,
    8 => DatePrecision.decade,
    < 8 => throw Exception("The precision was too low, value: $precision"),
    _ => throw Exception("Unexpected precision value: $precision"),
  };
}
