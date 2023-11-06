import 'dart:convert';

import 'package:http/http.dart';
import 'package:release_schedule/api/api_manager.dart';
import 'package:release_schedule/api/movie_api.dart';
import 'package:release_schedule/model/movie.dart';

class WikidataMovieData extends MovieData {
  int entityId;
  WikidataMovieData(String title, DateTime releaseDate, this.entityId)
      : super(title, releaseDate);

  @override
  bool same(MovieData other) {
    return other is WikidataMovieData && entityId == other.entityId;
  }
}

String createUpcomingMovieQuery(int limit) {
  return """
SELECT
  ?movie
  ?movieLabel
  (MIN(?releaseDate) as ?minReleaseDate)
WHERE {
  ?movie wdt:P31 wd:Q11424;         # Q11424 is the item for "film"
         wdt:P577 ?releaseDate;      # P577 is the "publication date" property
         wdt:P1476 ?title.
  FILTER (xsd:date(?releaseDate) >= xsd:date(NOW()))

  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
GROUP BY ?movie ?movieLabel
ORDER BY ?minReleaseDate
LIMIT $limit""";
}

class WikidataMovieApi implements MovieApi<WikidataMovieData> {
  ApiManager searchApi = ApiManager("https://www.wikidata.org/w/api.php");
  ApiManager queryApi =
      ApiManager("https://query.wikidata.org/sparql?format=json");

  @override
  Future<void> addMovieDetails(List<WikidataMovieData> movies) {
    // TODO: implement addMovieDetails
    throw UnimplementedError();
  }

  @override
  Future<List<WikidataMovieData>> getUpcomingMovies([int count = 100]) async {
    Response response = await queryApi
        .get("&query=${Uri.encodeComponent(createUpcomingMovieQuery(count))}");
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
