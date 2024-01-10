import 'package:flutter/material.dart';
import 'package:release_schedule/model/dates.dart';

class MovieData extends ChangeNotifier {
  bool _bookmarked = false;

  String? _title;
  DateWithPrecisionAndCountry? _releaseDate;

  // if it is entirely null the information was never loaded
  // if only the value is null it was loaded but nothing was found
  Dated<List<TextInLanguage>?>? _titles;
  Dated<List<TextInLanguage>?>? _labels;
  Dated<List<DateWithPrecisionAndCountry>?>? _releaseDates;
  Dated<String?>? _description;
  Dated<List<String>?>? _genres;

  MovieData();

  String? get title {
    return _title;
  }

  DateWithPrecisionAndCountry? get releaseDate {
    return _releaseDate;
  }

  bool get bookmarked {
    return _bookmarked;
  }

  Dated<String?>? get description {
    return _description;
  }

  Dated<List<DateWithPrecisionAndCountry>?>? get releaseDates {
    return _releaseDates;
  }

  Dated<List<String>?>? get genres {
    return _genres;
  }

  Dated<List<TextInLanguage>?>? get titles {
    return _titles;
  }

  Dated<List<TextInLanguage>?>? get labels {
    return _labels;
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
    List<DateWithPrecisionAndCountry>? releaseDates,
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

  void setDetails({
    bool? bookmarked,
    Dated<List<TextInLanguage>?>? titles,
    Dated<List<TextInLanguage>?>? labels,
    Dated<List<DateWithPrecisionAndCountry>?>? releaseDates,
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
      DateWithPrecisionAndCountry? mostPrecise =
          _releaseDates?.value?.isNotEmpty ?? false
              ? _releaseDates?.value?.reduce((a, b) =>
                  a.dateWithPrecision.precision > b.dateWithPrecision.precision
                      ? a
                      : b)
              : null;
      _releaseDate = mostPrecise;
    }
    if (genres != null) {
      _genres = genres;
    }
    notifyListeners();
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
            releaseDate!.dateWithPrecision.date.year ==
                other.releaseDate!.dateWithPrecision.date.year);
  }

  Map toJsonEncodable() {
    dynamic releaseDatesByCountry = _releaseDates?.toJsonEncodable(
        (releaseDates) => releaseDates
            ?.map((releaseDate) => releaseDate.toJsonEncodable())
            .toList());
    dynamic titlesByCountry = _titles?.toJsonEncodable(
        (titles) => titles?.map((e) => [e.text, e.language]).toList());
    dynamic labels = _labels?.toJsonEncodable(
        (labels) => labels?.map((e) => [e.text, e.language]).toList());
    dynamic genres = _genres?.toJsonEncodable((genres) => genres);
    return {
      "bookmarked": _bookmarked,
      "titles": titlesByCountry,
      "labels": labels,
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
          (json) =>
              Dated.fromJsonEncodable(json, (value) => value.cast<String>())),
      releaseDates:
          decodeOptionalJson<Dated<List<DateWithPrecisionAndCountry>?>>(
              json["releaseDates"],
              (json) => Dated.fromJsonEncodable(
                  json,
                  (value) => (value as List<dynamic>)
                      .map((releaseDate) =>
                          DateWithPrecisionAndCountry.fromJsonEncodable(
                              releaseDate))
                      .toList())),
      description: decodeOptionalJson<Dated<String?>>(json["description"],
          (json) => Dated.fromJsonEncodable(json, (value) => value)),
    );
  }
}

T? decodeOptionalJson<T>(dynamic json, T Function(dynamic) decode) {
  if (json == null) {
    return null;
  }
  return decode(json);
}

typedef TextInLanguage = ({String text, String language});

class DateWithPrecisionAndCountry {
  final DateWithPrecision dateWithPrecision;
  final String country;

  DateWithPrecisionAndCountry(
      DateTime date, DatePrecision precision, this.country)
      : dateWithPrecision = DateWithPrecision(date, precision);

  DateWithPrecisionAndCountry.fromJsonEncodable(List<dynamic> json)
      : dateWithPrecision = DateWithPrecision.fromJsonEncodable(json),
        country = json[2];

  toJsonEncodable() {
    return dateWithPrecision.toJsonEncodable() + [country];
  }

  @override
  String toString() {
    return "${dateWithPrecision.toString()} ($country)";
  }
}
