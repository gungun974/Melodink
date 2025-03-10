import 'package:diacritic/diacritic.dart';

bool compareFuzzySearch(String search, String field) {
  final terms =
      removeDiacritics(search).trim().toLowerCase().split(RegExp(r'[ ,_-]'));

  final fieldFiltered = removeDiacritics(field).toLowerCase();

  for (var i = 0; i < terms.length; i++) {
    final term = terms[i];

    if (!fieldFiltered.contains(term)) {
      return false;
    }
  }

  return true;
}
