import 'package:flutter/material.dart';

class Review {
  String score;
  String by;
  DateTime asOf;
  int count;

  Review(this.score, this.by, this.asOf, this.count);
}

typedef ReleaseDateInCountry = (String country, DateTime date);
typedef TitleInCountry = (String country, String title);

class MovieData extends ChangeNotifier {
  final String title;
  final DateTime releaseDate;
  bool _hasDetails = false;
  List<ReleaseDateInCountry> _releaseDates = [];
  List<String> _genres = [];
  List<TitleInCountry> _titles = [];
  List<Review> _reviews = [];

  List<ReleaseDateInCountry>? get releaseDates {
    return _releaseDates;
  }

  List<String>? get genres {
    return _genres;
  }

  List<TitleInCountry>? get titles {
    return _titles;
  }

  List<Review>? get reviews {
    return _reviews;
  }

  bool get hasDetails {
    return _hasDetails;
  }

  void setDetails(
      {List<ReleaseDateInCountry>? releaseDates,
      List<String>? genres,
      List<TitleInCountry>? titles,
      List<Review>? reviews}) {
    if (releaseDates != null) {
      _releaseDates = releaseDates;
    }
    if (genres != null) {
      _genres = genres;
    }
    if (titles != null) {
      _titles = titles;
    }
    if (reviews != null) {
      _reviews = reviews;
    }
    _hasDetails = true;
    notifyListeners();
  }

  @override
  String toString() {
    return "$title (${releaseDate.year}${_genres.isNotEmpty ? "; ${_genres.join(", ")}" : ""})";
  }

  bool same(MovieData other) {
    return title == other.title && releaseDate == other.releaseDate;
  }

  MovieData(this.title, this.releaseDate);
}
