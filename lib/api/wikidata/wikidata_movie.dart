import 'package:release_schedule/api/json_helper.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';

class WikidataMovieData extends MovieData {
  String entityId;
  Dated<List<String>?>? genreIds;
  Dated<String?>? wikipediaTitle;
  Dated<List<DateWithPrecisionAndPlace>?>? releaseDatesWithPlaceId;

  WikidataMovieData(this.entityId);

  WikidataMovieData.fromEncodable(Map encodable)
      : entityId = encodable["entityId"],
        super.fromJsonEncodable(encodable) {
    genreIds = decodeOptionalJson(
        encodable["genreIds"],
        (datedIds) => Dated<List<String>?>.fromJsonEncodable(
            datedIds,
            (ids) => decodeOptionalJson(
                ids, (ids) => (ids as List<dynamic>).cast<String>())));
    wikipediaTitle = decodeOptionalJson(encodable["wikipediaTitle"],
        (datedTitle) => Dated.fromJsonEncodable(datedTitle, (title) => title));
    releaseDatesWithPlaceId = decodeOptionalJson(
      encodable["releaseDatesWithPlaceId"],
      (datedReleaseDates) =>
          Dated<List<DateWithPrecisionAndPlace>?>.fromJsonEncodable(
        datedReleaseDates,
        (releaseDates) => decodeOptionalJson(
          releaseDates,
          (releaseDates) => (releaseDates as List<dynamic>)
              .map((releaseDate) =>
                  DateWithPrecisionAndPlace.fromJsonEncodable(releaseDate))
              .toList(),
        ),
      ),
    );
  }

  @override
  bool same(MovieData other) {
    return other is WikidataMovieData && entityId == other.entityId;
  }

  @override
  Map toJsonEncodable() {
    return super.toJsonEncodable()
      ..addAll({
        "entityId": entityId,
        "genreIds": genreIds?.toJsonEncodable((genres) => genres),
        "wikipediaTitle": wikipediaTitle?.toJsonEncodable((title) => title),
        "releaseDatesWithPlaceId": releaseDatesWithPlaceId?.toJsonEncodable(
            (dates) => dates?.map((date) => date.toJsonEncodable()).toList()),
      });
  }

  void updateWithWikidataEntity(Map<String, dynamic> entity) {
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
    List<DateWithPrecisionAndPlace> releaseDates =
        _getReleaseDates(claims).toList();
    releaseDatesWithPlaceId = Dated.now(releaseDates);
    updateReleaseDatePlacesFromCache();

    List<String>? newGenreIds = selectInJson<String>(
            claims, "${WikidataProperties.genre}.*.mainsnak.datavalue.value.id")
        .toList();
    String? newWikipediaTitle =
        selectInJson(entity, "sitelinks.enwiki.title").firstOrNull;
    if (newGenreIds.isNotEmpty) {
      genreIds = Dated.now(newGenreIds.toList());
      updateGenresFromCache(outdated: true);
    }
    if (newWikipediaTitle != null) {
      wikipediaTitle = Dated.now(newWikipediaTitle);
      updateWikipediaTitleFromCache();
    }

    setDetails(
      titles: Dated.now(titles),
      labels: Dated.now(labels),
    );
  }

  void updateGenresFromCache({bool outdated = false}) {
    List<String>? localGenreIds = genreIds?.value;
    if (localGenreIds != null) {
      List<String?>? newGenres =
          localGenreIds.map(getCachedLabelForEntity).toList();
      List<String>? newAvailableGenres = newGenres.whereType<String>().toList();
      if ((genres?.value?.isEmpty ?? true) ||
          newAvailableGenres.length == newGenres.length) {
        if (outdated) {
          setDetails(genres: Dated.outdated(newAvailableGenres));
        } else {
          setDetails(genres: Dated(newAvailableGenres, genreIds!.date));
        }
      }
    }
  }

  void updateWikipediaTitleFromCache() {
    final localWikipediaTitle = wikipediaTitle?.value;
    if (localWikipediaTitle != null) {
      Dated<String?>? description =
          getCachedWikipediaIntroTextForTitle(localWikipediaTitle);
      setDetails(description: description);
    }
  }

  void updateReleaseDatePlacesFromCache({bool outdated = false}) {
    final localReleaseDatesWithPlaceId = releaseDatesWithPlaceId?.value;
    if (localReleaseDatesWithPlaceId != null) {
      Iterable<DateWithPrecisionAndPlace>? releaseDates =
          localReleaseDatesWithPlaceId.map(
        (release) => DateWithPrecisionAndPlace(
          release.date,
          release.precision,
          getCachedLabelForEntity(release.place ?? ""),
        ),
      );
      if (outdated) {
        setDetails(releaseDates: Dated.outdated(releaseDates.toList()));
      } else {
        setDetails(
          releaseDates: Dated(
            releaseDates.toList(),
            releaseDatesWithPlaceId!.date,
          ),
        );
      }
    }
  }
}

Iterable<DateWithPrecisionAndPlace> _getReleaseDates(
    Map<String, dynamic> claims) {
  return selectInJson(claims, "${WikidataProperties.publicationDate}.*")
      .where((dateClaim) => dateClaim["rank"] != "deprecated")
      .expand<DateWithPrecisionAndPlace>((dateClaim) {
    var value = selectInJson(dateClaim, "mainsnak.datavalue.value").first;
    Iterable<String?> placeIds = (selectInJson<String>(dateClaim,
        "qualifiers.${WikidataProperties.placeOfPublication}.*.datavalue.value.id"));
    if (placeIds.isEmpty) {
      placeIds = [null];
    }
    return placeIds.map((placeId) => DateWithPrecisionAndPlace(
          DateTime.parse(value["time"]),
          precisionFromWikidata(value["precision"]),
          placeId,
        ));
  });
}
