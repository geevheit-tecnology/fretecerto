import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/quote_repository.dart';
import '../domain/saved_quote.dart';

final quoteHistoryProvider =
    NotifierProvider<QuoteHistoryNotifier, List<SavedQuote>>(
      QuoteHistoryNotifier.new,
    );

class QuoteHistoryNotifier extends Notifier<List<SavedQuote>> {
  late final QuoteRepository _repository;

  @override
  List<SavedQuote> build() {
    _repository = QuoteRepository();
    _loadRemote();
    return const [];
  }

  Future<void> save(SavedQuote quote) async {
    state = [quote, ...state].take(30).toList(growable: false);
    try {
      final saved = await _repository.save(quote);
      state = [
        saved,
        ...state.where((item) => item.id != quote.id),
      ].take(30).toList(growable: false);
    } catch (_) {
      // Mantem a cotacao local para o usuario nao perder o trabalho.
    }
  }

  Future<void> _loadRemote() async {
    final quotes = await _repository.recentQuotes();
    if (quotes.isNotEmpty) {
      state = quotes;
    }
  }
}
