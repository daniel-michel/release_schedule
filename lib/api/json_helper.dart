/// Select values in nested [List] and [Map] structures using a path that may contain wildcards.
///
/// The maps must always use [String] keys.
/// The [path] is a dot-separated list of keys and indices.
/// The wildcard "*" can be used to select all elements of a list or map.
/// The wildcard "**" can be used to select all elements of a list or map and all elements of nested lists and maps.
///
/// Returns an [Iterable] of the selected values.
///
/// Also see [selectInJsonWithPath] for a version that returns the path to the selected values.
Iterable<T> selectInJson<T>(dynamic json, String path) {
  return selectInJsonWithPath<T>(json, path).map((e) => e.value);
}

/// Select values in nested [List] and [Map] structures using a path that may contain wildcards.
///
/// The maps must always use [String] keys.
/// The [path] is a dot-separated list of keys and indices.
/// The wildcard "*" can be used to select all elements of a list or map.
/// The wildcard "**" can be used to select all elements of a list or map and all elements of nested lists and maps.+
///
/// Returns an [Iterable] of the selected values and their path.
Iterable<({T value, String path})> selectInJsonWithPath<T>(
    dynamic json, String path) sync* {
  if (path.isEmpty) {
    if (json is T) {
      yield (value: json, path: "");
    }
    return;
  }
  List<String> pathParts = path.split(".");
  String first = pathParts.removeAt(0);
  String rest = pathParts.join(".");
  ({T value, String path}) addFirstToPath(({T value, String path}) element) {
    return (
      value: element.value,
      path: element.path.isEmpty ? first : "$first.${element.path}"
    );
  }

  if (first == "*" || first == "**") {
    String continueWithPath = first == "*" ? rest : path;
    if (first == "**") {
      yield* selectInJsonWithPath<T>(json, rest);
    }
    if (json is List) {
      yield* json
          .expand((e) => selectInJsonWithPath<T>(e, continueWithPath))
          .map(addFirstToPath);
    } else if (json is Map) {
      for (String key in json.keys) {
        yield* selectInJsonWithPath<T>(json[key], continueWithPath)
            .map(addFirstToPath);
      }
    }
  } else if (json is List) {
    try {
      int index = int.parse(first);
      yield* selectInJsonWithPath<T>(json[index], rest);
    } catch (e) {
      // The first part of the path is not an index or out of bounds -> ignore
    }
  } else if (json is Map) {
    dynamic value = json[first];
    if (value != null) {
      yield* selectInJsonWithPath<T>(value, rest);
    }
  }
}
