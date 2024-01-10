import 'package:flutter/material.dart';
import 'package:release_schedule/model/dates.dart';

class MovieData extends ChangeNotifier {
  String _title;
  DateWithPrecisionAndCountry _releaseDate;
  bool _bookmarked = false;

  bool _hasDetails = false;
  String? _description;
  List<DateWithPrecisionAndCountry>? _releaseDates;
  List<String>? _genres;
  List<TitleInLanguage>? _titles;

  MovieData(this._title, this._releaseDate);

  String get title {
    return _title;
  }

  DateWithPrecisionAndCountry get releaseDate {
    return _releaseDate;
  }

  bool get bookmarked {
    return _bookmarked;
  }

  get description {
    return _description;
  }

  List<DateWithPrecisionAndCountry>? get releaseDates {
    return _releaseDates;
  }

  List<String>? get genres {
    return _genres;
  }

  List<TitleInLanguage>? get titles {
    return _titles;
  }

  bool get hasDetails {
    return _hasDetails;
  }

  /// Updates the information with that of a new version of the movie
  /// but ignores fields that are user controlled, like whether the movie was bookmarked.
  void updateWithNewIgnoringUserControlled(MovieData movie) {
    setDetails(
        title: movie.title,
        releaseDate: movie.releaseDate,
        description: movie.description,
        releaseDates: movie.releaseDates,
        genres: movie.genres,
        titles: movie.titles);
  }

  void setDetails(
      {String? title,
      DateWithPrecisionAndCountry? releaseDate,
      bool? bookmarked,
      String? description,
      List<DateWithPrecisionAndCountry>? releaseDates,
      List<String>? genres,
      List<TitleInLanguage>? titles}) {
    if (title != null) {
      _title = title;
    }
    if (releaseDate != null) {
      _releaseDate = releaseDate;
    }
    if (bookmarked != null) {
      _bookmarked = bookmarked;
    }
    if (description != null) {
      _description = description;
    }
    if (releaseDates != null) {
      _releaseDates = releaseDates;
    }
    if (genres != null) {
      _genres = genres;
    }
    if (titles != null) {
      _titles = titles;
    }
    _hasDetails = true;
    notifyListeners();
  }

  @override
  String toString() {
    return "$title (${_releaseDate.toString()}${_genres?.isNotEmpty ?? false ? "; ${_genres?.join(", ")}" : ""})";
  }

  bool same(MovieData other) {
    return title == other.title &&
        releaseDate.dateWithPrecision == other.releaseDate.dateWithPrecision;
  }

  Map toJsonEncodable() {
    List? releaseDatesByCountry =
        _releaseDates?.map((e) => e.toJsonEncodable()).toList();
    List? titlesByCountry = _titles?.map((e) => [e.title, e.language]).toList();
    return {
      "title": title,
      "releaseDate": _releaseDate.toJsonEncodable(),
      "bookmarked": _bookmarked,
      "description": _description,
      "releaseDates": releaseDatesByCountry,
      "genres": genres,
      "titles": titlesByCountry,
    };
  }

  MovieData.fromJsonEncodable(Map json)
      : _title = json["title"],
        _releaseDate =
            DateWithPrecisionAndCountry.fromJsonEncodable(json["releaseDate"]) {
    setDetails(
        bookmarked: json["bookmarked"] as bool,
        description: json["description"] as String?,
        genres: (json["genres"] as List<dynamic>?)
            ?.map((genre) => genre as String)
            .toList(),
        releaseDates: json["releaseDates"] != null
            ? (json["releaseDates"] as List<dynamic>)
                .map((release) =>
                    DateWithPrecisionAndCountry.fromJsonEncodable(release))
                .toList()
            : null,
        titles: json["titles"] != null
            ? (json["titles"] as List<dynamic>)
                .map((title) =>
                    (title: title[0], language: title[1]) as TitleInLanguage)
                .toList()
            : null);
  }
}

typedef TitleInLanguage = ({String title, String language});

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
