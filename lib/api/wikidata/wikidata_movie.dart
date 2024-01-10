import 'package:release_schedule/api/json_helper.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';

class WikidataMovieData extends MovieData {
  String entityId;
  WikidataMovieData(this.entityId);

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
    Map<String, dynamic> claims = entity["claims"];
    List<TextInLanguage>? titles = selectInJson(
            claims, "${WikidataProperties.title}.*.mainsnak.datavalue.value")
        .map((value) => (
              text: value["text"],
              language: value["language"],
            ) as TextInLanguage)
        .toList();
    List<TextInLanguage>? labels = selectInJson(entity, "labels.*")
        .map((value) => (
              text: value["value"],
              language: value["language"],
            ) as TextInLanguage)
        .toList();
    String? wikipediaTitle = selectInJson(entity, "sitelinks.enwiki.url")
        .firstOrNull
        ?.split("/")
        .last;
    Dated<String?>? description = wikipediaTitle != null
        ? getCachedWikipediaExplainTextFotTitle(wikipediaTitle)
        : null;
    List<DateWithPrecisionAndCountry> releaseDates =
        _getReleaseDates(claims).toList();
    // Sort release dates with higher precision to the beginning
    releaseDates.sort((a, b) => -a.dateWithPrecision.precision.index
        .compareTo(b.dateWithPrecision.precision.index));
    List<String>? genres = selectInJson<String>(
            claims, "${WikidataProperties.genre}.*.mainsnak.datavalue.value.id")
        .map(getCachedLabelForEntity)
        .toList();
    WikidataMovieData movie = WikidataMovieData(entityId);
    movie.setDetails(
      titles: Dated.now(titles),
      labels: Dated.now(labels),
      releaseDates: Dated.now(releaseDates),
      genres: Dated.now(genres),
      description: description,
    );
    return movie;
  }

  static Iterable<DateWithPrecisionAndCountry> _getReleaseDates(
      Map<String, dynamic> claims) {
    return selectInJson(claims, "${WikidataProperties.publicationDate}.*")
        .where((dateClaim) => dateClaim["rank"] != "deprecated")
        .expand<DateWithPrecisionAndCountry>((dateClaim) {
      var value = selectInJson(dateClaim, "mainsnak.datavalue.value").first;
      Iterable<String> countries = (selectInJson<String>(dateClaim,
              "qualifiers.${WikidataProperties.placeOfPublication}.*.datavalue.value.id"))
          .map(getCachedLabelForEntity);
      if (countries.isEmpty) {
        countries = ["unknown location"];
      }
      return countries.map((country) => DateWithPrecisionAndCountry(
          DateTime.parse(value["time"]),
          precisionFromWikidata(value["precision"]),
          country));
    });
  }
}
