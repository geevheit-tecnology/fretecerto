import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer.dart';

class CustomerRepository {
  CustomerRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Customer>> recentCustomers() async {
    try {
      final rows = await _client
          .from('customers')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      return rows.map((row) => Customer.fromMap(row)).toList();
    } on PostgrestException {
      return const [];
    }
  }

  Future<Customer> save(Customer customer) async {
    final rows = await _client
        .from('customers')
        .upsert(customer.toInsert(), onConflict: 'document')
        .select()
        .limit(1);
    return Customer.fromMap(rows.single);
  }
}
