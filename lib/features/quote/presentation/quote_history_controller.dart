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

  Future<void> updateStatus(SavedQuote quote, String status) async {
    final updated = quote.copyWith(status: status);
    state = [for (final item in state) item.id == quote.id ? updated : item];
    try {
      await _repository.updateStatus(quote.id, status);
    } catch (_) {
      // Mantem o status local mesmo se a conexao falhar.
    }
  }

  Future<void> delete(SavedQuote quote) async {
    state = state.where((item) => item.id != quote.id).toList(growable: false);
    try {
      await _repository.delete(quote.id);
    } catch (_) {
      // Se estiver offline, pelo menos remove da lista visivel nesta sessao.
    }
  }

  Future<void> _loadRemote() async {
    final quotes = await _repository.recentQuotes();
    if (quotes.isNotEmpty) {
      state = quotes;
    }
  }
}
