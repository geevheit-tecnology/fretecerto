import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/saved_quote.dart';

final quoteHistoryProvider =
    NotifierProvider<QuoteHistoryNotifier, List<SavedQuote>>(
      QuoteHistoryNotifier.new,
    );

class QuoteHistoryNotifier extends Notifier<List<SavedQuote>> {
  @override
  List<SavedQuote> build() => const [];

  void save(SavedQuote quote) {
    state = [quote, ...state].take(30).toList(growable: false);
  }
}
