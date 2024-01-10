import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/movie.dart';

void main() {
  group('MovieData', () {
    MovieData firstMovie = MovieData()
      ..setNewDetails(
        labels: [(text: 'Title 1', language: 'en')],
        releaseDates: [
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US')
        ],
      );
    MovieData secondMovie = MovieData()
      ..setNewDetails(
        labels: [(text: 'Title 2', language: 'en')],
        releaseDates: [
          DateWithPrecisionAndCountry(
              DateTime(2023, 1, 1), DatePrecision.day, 'US')
        ],
      );

    test('updateWithNew() updates all fields', () {
      final movie1 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie);
      final movie2 = MovieData()
        ..updateWithNewIgnoringUserControlled(secondMovie)
        ..setNewDetails(
          releaseDates: [
            DateWithPrecisionAndCountry(
                DateTime(2023, 1, 1), DatePrecision.day, 'UK')
          ],
          genres: ['Action', 'Adventure'],
          titles: [(text: 'Titel 2', language: 'de')],
        );
      movie1.updateWithNewIgnoringUserControlled(movie2);
      expect(movie1.title, equals('Title 2'));
      expect(movie1.releaseDate?.country, equals('UK'));
      expect(movie1.releaseDates?.value?.length, equals(1));
      expect(movie1.releaseDates?.value?[0].country, equals('UK'));
      expect(movie1.genres?.value?.length, equals(2));
      expect(movie1.genres?.value?[0], equals('Action'));
      expect(movie1.genres?.value?[1], equals('Adventure'));
      expect(movie1.titles?.value?.length, equals(1));
      expect(movie1.titles?.value?[0].text, equals('Titel 2'));
      expect(movie1.titles?.value?[0].language, equals('de'));
    });

    test('same() returns true for same title and release year', () {
      final movie1 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie);
      final movie2 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie)
        ..setNewDetails(
          releaseDates: [
            DateWithPrecisionAndCountry(
                DateTime(2023, 4, 27), DatePrecision.day, 'US')
          ],
        );
      expect(movie1.same(movie2), isTrue);
    });

    test('same() returns false for different title', () {
      final movie1 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie);
      final movie2 = MovieData()
        ..updateWithNewIgnoringUserControlled(secondMovie);
      expect(movie1.same(movie2), isFalse);
    });

    test('same() returns false for different release years', () {
      final movie1 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie);
      final movie2 = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie)
        ..setNewDetails(
          releaseDates: [
            DateWithPrecisionAndCountry(
                DateTime(2022, 1, 1), DatePrecision.day, 'US')
          ],
        );
      expect(movie1.same(movie2), isFalse);
    });
    test('can be encoded to JSON and back', () {
      final movie = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie)
        ..setNewDetails(
          genres: ['Action', 'Adventure'],
        );
      final json = movie.toJsonEncodable();
      final movie2 = MovieData.fromJsonEncodable(json);
      expect(movie2.title, equals('Title 1'));
      expect(movie2.releaseDate?.country, equals('US'));
      expect(movie2.releaseDates?.value?.length, equals(1));
      expect(movie2.releaseDates?.value?[0].country, equals('US'));
      expect(movie2.genres?.value?.length, equals(2));
      expect(movie2.genres?.value?[0], equals('Action'));
      expect(movie2.genres?.value?[1], equals('Adventure'));
      expect(movie2.titles, equals(null));
    });

    test('toString()', () {
      final movie = MovieData()
        ..updateWithNewIgnoringUserControlled(firstMovie)
        ..setNewDetails(
          genres: ['Action', 'Adventure'],
        );
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
