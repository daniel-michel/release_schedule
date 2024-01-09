import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';

void main() {
  group('MovieData', () {
    test('updateWithNew() updates all fields', () {
      final movie1 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      final movie2 = MovieData(
          'Title 2',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'UK'));
      movie2.setDetails(releaseDates: [
        DateWithPrecisionAndCountry(
            DateTime(2023, 1, 1), DatePrecision.day, 'US')
      ], genres: [
        'Action',
        'Adventure'
      ], titles: [
        (title: 'Title 2', language: 'en')
      ]);
      movie1.updateWithNewIgnoringUserControlled(movie2);
      expect(movie1.title, equals('Title 2'));
      expect(movie1.releaseDate.country, equals('UK'));
      expect(movie1.releaseDates!.length, equals(1));
      expect(movie1.releaseDates![0].country, equals('US'));
      expect(movie1.genres!.length, equals(2));
      expect(movie1.genres![0], equals('Action'));
      expect(movie1.genres![1], equals('Adventure'));
      expect(movie1.titles!.length, equals(1));
      expect(movie1.titles![0].title, equals('Title 2'));
      expect(movie1.titles![0].language, equals('en'));
    });

    test('same() returns true for same title and release date', () {
      final movie1 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      final movie2 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      expect(movie1.same(movie2), isTrue);
    });

    test('same() returns false for different title', () {
      final movie1 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      final movie2 = MovieData(
          'Title 2',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      expect(movie1.same(movie2), isFalse);
    });

    test('same() returns false for different release date', () {
      final movie1 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      final movie2 = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 2), DatePrecision.day, 'US'));
      expect(movie1.same(movie2), isFalse);
    });
    test('can be encoded to JSON and back', () {
      final movie = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      movie.setDetails(releaseDates: [
        DateWithPrecisionAndCountry(
            DateTime(2023, 1, 1), DatePrecision.day, 'US')
      ], genres: [
        'Action',
        'Adventure'
      ], titles: [
        (title: 'Title 2', language: 'en')
      ]);
      final json = movie.toJsonEncodable();
      final movie2 = MovieData.fromJsonEncodable(json);
      expect(movie2.title, equals('Title 1'));
      expect(movie2.releaseDate.country, equals('US'));
      expect(movie2.releaseDates!.length, equals(1));
      expect(movie2.releaseDates![0].country, equals('US'));
      expect(movie2.genres!.length, equals(2));
      expect(movie2.genres![0], equals('Action'));
      expect(movie2.genres![1], equals('Adventure'));
      expect(movie2.titles!.length, equals(1));
      expect(movie2.titles![0].title, equals('Title 2'));
      expect(movie2.titles![0].language, equals('en'));
    });

    test('toString()', () {
      final movie = MovieData(
          'Title 1',
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US'));
      movie.setDetails(releaseDates: [
        DateWithPrecisionAndCountry(
            DateTime(2023, 1, 1), DatePrecision.day, 'US')
      ], genres: [
        'Action',
        'Adventure'
      ], titles: [
        (title: 'Title 2', language: 'en')
      ]);
      expect(movie.toString(),
          equals('Title 1 (January 1, 2023 (US); Action, Adventure)'));
    });
  });

  group('DateWithPrecisionAndCountry', () {
    test('can be encoded to JSON and back', () {
      final date = DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US');
      final json = date.toJsonEncodable();
      final date2 = DateWithPrecisionAndCountry.fromJsonEncodable(json);
      expect(date2.dateWithPrecision, equals(date.dateWithPrecision));
      expect(date2.dateWithPrecision.precision,
          equals(date.dateWithPrecision.precision));
      expect(date2.country, equals(date.country));
    });

    test('toString()', () {
      final date = DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.day, 'US');
      expect(date.toString(), equals('January 1, 2023 (US)'));
    });

    test('toString() with month precision', () {
      final date = DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.month, 'US');
      expect(date.toString(), equals('January 2023 (US)'));
    });

    test('toString() with year precision', () {
      final date = DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.year, 'US');
      expect(date.toString(), equals('2023 (US)'));
    });

    test('toString() with decade precision', () {
      final date = DateWithPrecisionAndCountry(
          DateTime(2023, 1, 1), DatePrecision.decade, 'US');
      expect(date.toString(), equals('2020s (US)'));
    });
  });
}
