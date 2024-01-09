import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/api/json_helper.dart';

void main() {
  group("selectInJson", () {
    late Map<String, dynamic> json;

    setUp(() {
      json = {
        "a": {
          "b": [
            {"c": 1},
            {"c": 2},
            {"c": 3},
          ],
          "c": 4,
        },
        "d": [
          {"e": 5},
          {"e": 6},
          {"e": "7"},
          {"e": 7},
        ]
      };
    });

    test("should select a value", () {
      expect(selectInJson<int>(json, "a.b.1.c").toList(), equals([2]));
    });

    test("should select multiple values", () {
      expect(selectInJson<int>(json, "a.b.*.c").toList(), equals([1, 2, 3]));
    });

    test("should select multiple values with nested lists", () {
      expect(selectInJson<int>(json, "a.**.c").toList(), equals([4, 1, 2, 3]));
    });

    test("should select multiple values with nested lists and maps", () {
      expect(selectInJson<int>(json, "**.e").toList(), equals([5, 6, 7]));
    });
  });
}
