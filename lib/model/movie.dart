import 'package:flutter/material.dart';
import 'package:release_schedule/api/json_helper.dart';
import 'package:release_schedule/model/dates.dart';

class MovieData extends ChangeNotifier {
  bool _bookmarked = false;
  bool _loading = false;

  String? _title;
  DateWithPrecisionAndPlace? _releaseDate;

  // if it is entirely null the information was never loaded
  // if only the value is null it was loaded but nothing was found
  Dated<List<TextInLanguage>?>? _titles;
  Dated<List<TextInLanguage>?>? _labels;
  Dated<List<DateWithPrecisionAndPlace>?>? _releaseDates;
  Dated<String?>? _description;
  Dated<List<String>?>? _genres;

  MovieData();

  String? get title {
    return _title;
  }

  DateWithPrecisionAndPlace? get releaseDate {
    return _releaseDate;
  }

  bool get bookmarked {
    return _bookmarked;
  }

  bool get loading {
    return _loading;
  }

  Dated<List<TextInLanguage>?>? get titles {
    return _titles;
  }

  Dated<List<TextInLanguage>?>? get labels {
    return _labels;
  }

  Dated<String?>? get description {
    return _description;
  }

  Dated<List<DateWithPrecisionAndPlace>?>? get releaseDates {
    return _releaseDates;
  }

  Dated<List<String>?>? get genres {
    return _genres;
  }

  void setLoading(bool updating) {
    _loading = updating;
    notifyListeners();
  }

  /// Updates the information with that of a new version of the movie
  /// but ignores fields that are user controlled, like whether the movie was bookmarked.
  void updateWithNewIgnoringUserControlled(MovieData movie) {
    setDetails(
      titles: movie.titles,
      labels: movie.labels,
      releaseDates: movie.releaseDates,
      genres: movie.genres,
      description: movie.description,
    );
  }

  void setNewDetails({
    bool? bookmarked,
    List<TextInLanguage>? titles,
    List<TextInLanguage>? labels,
    List<DateWithPrecisionAndPlace>? releaseDates,
    List<String>? genres,
    String? description,
  }) {
    setDetails(
      bookmarked: bookmarked,
      titles: titles != null ? Dated.now(titles) : null,
      labels: labels != null ? Dated.now(labels) : null,
      releaseDates: releaseDates != null ? Dated.now(releaseDates) : null,
      genres: genres != null ? Dated.now(genres) : null,
      description: description != null ? Dated.now(description) : null,
    );
  }

  void setOutdated() {
    setDetails(
      titles: Dated.outdated(_titles?.value),
      labels: Dated.outdated(_labels?.value),
      releaseDates: Dated.outdated(_releaseDates?.value),
      genres: Dated.outdated(_genres?.value),
      description: Dated.outdated(_description?.value),
    );
  }

  void setDetails({
    bool? bookmarked,
    Dated<List<TextInLanguage>?>? titles,
    Dated<List<TextInLanguage>?>? labels,
    Dated<List<DateWithPrecisionAndPlace>?>? releaseDates,
    Dated<List<String>?>? genres,
    Dated<String?>? description,
  }) {
    if (bookmarked != null) {
      _bookmarked = bookmarked;
    }
    if (titles != null) {
      _titles = titles;
    }
    if (labels != null) {
      _labels = labels;
    }
    if (titles != null || labels != null) {
      _title = null;
      _title ??= _titles?.value
          ?.where((title) => title.language == "en")
          .firstOrNull
          ?.text;
      _title ??= _labels?.value
          ?.where((label) => label.language == "en")
          .firstOrNull
          ?.text;
      _title ??= _labels?.value?.firstOrNull?.text;
      _title ??= _titles?.value?.firstOrNull?.text;
    }
    if (description != null) {
      _description = description;
    }
    if (releaseDates != null) {
      _releaseDates = releaseDates;
      DateWithPrecisionAndPlace? mostPrecise =
          _releaseDates?.value?.isNotEmpty ?? false
              ? _releaseDates?.value
                  ?.reduce((a, b) => a.precision < b.precision ? b : a)
              : null;
      _releaseDate = mostPrecise;
    }
    if (genres != null) {
      _genres = genres;
    }
    notifyListeners();
  }

  MovieData copy() {
    return MovieData()..updateWithNewIgnoringUserControlled(this);
  }

  @override
  String toString() {
    return "$title (${_releaseDate.toString()}${_genres?.value?.isNotEmpty ?? false ? "; ${_genres?.value?.join(", ")}" : ""})";
  }

  bool same(MovieData other) {
    return title != null &&
        title == other.title &&
        (releaseDate == null ||
            other.releaseDate == null ||
            releaseDate!.date.year == other.releaseDate!.date.year);
  }

  Map toJsonEncodable() {
    dynamic releaseDatesByCountry = _releaseDates?.toJsonEncodable(
        (releaseDates) => releaseDates
            ?.map((releaseDate) => releaseDate.toJsonEncodable())
            .toList());
    dynamic titlesByLanguage = _titles?.toJsonEncodable(
        (titles) => titles?.map((e) => [e.text, e.language]).toList());
    dynamic labelsByLanguage = _labels?.toJsonEncodable(
        (labels) => labels?.map((e) => [e.text, e.language]).toList());
    dynamic genres = _genres?.toJsonEncodable((genres) => genres);
    return {
      "bookmarked": _bookmarked,
      "titles": titlesByLanguage,
      "labels": labelsByLanguage,
      "releaseDates": releaseDatesByCountry,
      "genres": genres,
      "description":
          _description?.toJsonEncodable((description) => description),
    };
  }

  MovieData.fromJsonEncodable(Map json) {
    setDetails(
      bookmarked: json["bookmarked"] as bool? ?? false,
      titles: decodeOptionalJson<Dated<List<TextInLanguage>?>>(
          json["titles"],
          (json) => Dated.fromJsonEncodable(
              json,
              (value) => (value as List<dynamic>)
                  .map((title) =>
                      (text: title[0], language: title[1]) as TextInLanguage)
                  .toList())),
      labels: decodeOptionalJson<Dated<List<TextInLanguage>?>>(
          json["labels"],
          (json) => Dated.fromJsonEncodable(
              json,
              (value) => (value as List<dynamic>)
                  .map((label) =>
                      (text: label[0], language: label[1]) as TextInLanguage)
                  .toList())),
      genres: decodeOptionalJson<Dated<List<String>?>>(
          json["genres"],
          (json) => Dated.fromJsonEncodable(
              json,
              (value) => decodeOptionalJson(
                    value,
                    (genres) => (genres as List<dynamic>).cast<String>(),
                  ))),
      releaseDates: decodeOptionalJson<Dated<List<DateWithPrecisionAndPlace>?>>(
          json["releaseDates"],
          (json) => Dated.fromJsonEncodable(
              json,
              (value) => (value as List<dynamic>)
                  .map((releaseDate) =>
                      DateWithPrecisionAndPlace.fromJsonEncodable(releaseDate))
                  .toList())),
      description: decodeOptionalJson<Dated<String?>>(json["description"],
          (json) => Dated.fromJsonEncodable(json, (value) => value)),
    );
  }
}

typedef TextInLanguage = ({String text, String language});

class DateWithPrecisionAndPlace {
  final DateWithPrecision dateWithPrecision;
  final String? _place;

  DateWithPrecisionAndPlace(DateTime date, DatePrecision precision, this._place)
      : dateWithPrecision = DateWithPrecision(date, precision);

  DateWithPrecisionAndPlace.fromJsonEncodable(List<dynamic> json)
      : dateWithPrecision = DateWithPrecision.fromJsonEncodable(json),
        _place = json[2];

  bool get isPlaceKnown => _place != null;
  String? get place => _place;
  DateTime get date => dateWithPrecision.date;
  DatePrecision get precision => dateWithPrecision.precision;

  toJsonEncodable() {
    return dateWithPrecision.toJsonEncodable() + [place];
  }

  @override
  String toString() {
    return dateWithPrecision.toString() + (place != null ? " ($place)" : "");
  }
}
