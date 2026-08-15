import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/saved_quote.dart';

class QuoteRepository {
  QuoteRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SavedQuote>> recentQuotes() async {
    try {
      final rows = await _client
          .from('quotes')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      return rows.map((row) => SavedQuote.fromMap(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<SavedQuote> save(SavedQuote quote) async {
    final payload = quote.toInsert()
      ..['created_by'] = _client.auth.currentUser?.id;
    final row = await _client.from('quotes').insert(payload).select().single();
    return SavedQuote.fromMap(row);
  }
}
