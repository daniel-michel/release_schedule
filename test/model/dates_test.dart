import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/dates.dart';

void main() {
  group("DatePrecisionComparison", () {
    test("can compare with inequality", () {
      expect(DatePrecision.decade < DatePrecision.year, isTrue);
      expect(DatePrecision.year <= DatePrecision.year, isTrue);
      expect(DatePrecision.month > DatePrecision.day, isFalse);
      expect(DatePrecision.day > DatePrecision.day, isFalse);
      expect(DatePrecision.hour >= DatePrecision.month, isTrue);
    });

    test("can compare with equality", () {
      expect(DatePrecision.decade == DatePrecision.decade, isTrue);
      expect(DatePrecision.year != DatePrecision.decade, isTrue);
    });
  });

  test("simplifyDatesToPrecision", () {
    expect(simplifyDateToPrecision(DateTime(2024, 5, 14), DatePrecision.decade),
        equals(DateTime(2020, 1, 1)));
    expect(simplifyDateToPrecision(DateTime(2024, 5, 14), DatePrecision.year),
        equals(DateTime(2024, 1, 1)));
    expect(simplifyDateToPrecision(DateTime(2024, 5, 14), DatePrecision.month),
        equals(DateTime(2024, 5, 1)));
    expect(
        simplifyDateToPrecision(
            DateTime(2024, 5, 14, 10, 42), DatePrecision.day),
        equals(DateTime(2024, 5, 14)));
    expect(
        simplifyDateToPrecision(
            DateTime(2024, 5, 14, 10, 42), DatePrecision.hour),
        equals(DateTime(2024, 5, 14, 10)));
    expect(
        simplifyDateToPrecision(
            DateTime(2024, 5, 14, 10, 42, 12), DatePrecision.minute),
        equals(DateTime(2024, 5, 14, 10, 42)));
  });

  group("DateWithPrecision", () {
    test("includes", () {
      DateTime originalDate = DateTime(2024, 5, 14, 15, 42, 12);
      expect(
          DateWithPrecision(originalDate, DatePrecision.minute)
              .includes(DateTime(2024, 5, 14, 15, 42, 12)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.minute)
              .includes(DateTime(2024, 5, 14, 15, 43, 1)),
          isFalse);
      expect(
          DateWithPrecision(originalDate, DatePrecision.hour)
              .includes(DateTime(2024, 5, 14, 15, 42, 12)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.hour)
              .includes(DateTime(2024, 5, 14, 16, 10, 12)),
          isFalse);
      expect(
          DateWithPrecision(originalDate, DatePrecision.day)
              .includes(DateTime(2024, 5, 14)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.day)
              .includes(DateTime(2024, 5, 15)),
          isFalse);
      expect(
          DateWithPrecision(originalDate, DatePrecision.month)
              .includes(DateTime(2024, 5, 20)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.month)
              .includes(DateTime(2024, 6, 10)),
          isFalse);
      expect(
          DateWithPrecision(originalDate, DatePrecision.year)
              .includes(DateTime(2024, 12, 31)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.year)
              .includes(DateTime(2025, 1, 1)),
          isFalse);
      expect(
          DateWithPrecision(originalDate, DatePrecision.decade)
              .includes(DateTime(2029, 12, 31)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.decade)
              .includes(DateTime(2020, 1, 1)),
          isTrue);
      expect(
          DateWithPrecision(originalDate, DatePrecision.decade)
              .includes(DateTime(2030, 1, 1)),
          isFalse);
    });

    test("toString", () {
      DateTime date = DateTime(2024, 5, 14, 15, 42, 12);
      expect(DateWithPrecision(date, DatePrecision.minute).toString(),
          equals("May 14, 2024, 15:42"));
      expect(DateWithPrecision(date, DatePrecision.hour).toString(),
          equals("May 14, 2024, 15"));
      expect(DateWithPrecision(date, DatePrecision.day).toString(),
          equals("May 14, 2024"));
      expect(DateWithPrecision(date, DatePrecision.month).toString(),
          equals("May 2024"));
      expect(DateWithPrecision(date, DatePrecision.year).toString(),
          equals("2024"));
      expect(DateWithPrecision(date, DatePrecision.decade).toString(),
          equals("2020s"));
    });
  });
}
