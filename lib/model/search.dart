import 'dart:math';

class Scored<T> {
  T data;
  double score;
  Scored(this.data, this.score);

  @override
  toString() => '$data: $score';
}

List<T> searchList<T>(
  List<T> list,
  String search,
  List<String> Function(T item) getTexts,
) {
  List<Scored<T>> scored = list.map((e) {
    double score = 0;
    List<String> texts = getTexts(e);
    for (var text in texts) {
      score = max(searchMatch(search, text), score);
    }
    return Scored(e, score);
  }).toList();
  scored = scored.where((element) => element.score > 0.7).toList();
  scored.sort((a, b) => (b.score - a.score).sign.toInt());
  return scored.map((e) => e.data).toList();
}

double searchMatch(String search, String text) {
  double matchPoints = 0;
  List<String> searchParts = [search.toLowerCase()];
  List<String> textParts = [text.toLowerCase()];

  while (searchParts.isNotEmpty && textParts.isNotEmpty) {
    int bestSpi = 0;
    int bestTpi = 0;
    int bestSci = 0;
    int bestTci = 0;
    int bestLength = 0;

    for (int spi = 0; spi < searchParts.length; spi++) {
      String searchPart = searchParts[spi];
      for (int tpi = 0; tpi < textParts.length; tpi++) {
        String textPart = textParts[tpi];
        for (int sci = 0; sci < searchPart.length; sci++) {
          for (int tci = 0; tci < textPart.length; tci++) {
            int length = 0;
            int maxLength = min(searchPart.length - sci, textPart.length - tci);
            while (length < maxLength &&
                searchPart[sci + length] == textPart[tci + length]) {
              length++;
            }
            if (length > bestLength) {
              bestSpi = spi;
              bestTpi = tpi;
              bestSci = sci;
              bestTci = tci;
              bestLength = length;
            }
          }
        }
      }
    }

    if (bestLength == 0) break;
    matchPoints += bestLength.toDouble() - 0.5;
    String searchPart = searchParts[bestSpi];
    searchParts.removeAt(bestSpi);
    searchParts.addAll([
      searchPart.substring(0, bestSci),
      searchPart.substring(bestSci + bestLength),
    ]);
    searchParts.removeWhere((x) => x.isEmpty);

    String textPart = textParts[bestTpi];
    textParts.removeAt(bestTpi);
    textParts.addAll([
      textPart.substring(0, bestTci),
      textPart.substring(bestTci + bestLength),
    ]);
    textParts.removeWhere((x) => x.isEmpty);
  }

  // normalize result
  double matchScore = matchPoints / (search.length - 0.5);
  double missCut = pow(
          (textParts.fold(0, (acc, part) => acc + part.length) / text.length),
          2) *
      0.2 *
      matchScore;
  double score = matchScore - missCut;
  return score;
}
