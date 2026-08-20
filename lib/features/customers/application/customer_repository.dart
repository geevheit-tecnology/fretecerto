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
    if (customer.id != null) {
      final row = await _client
          .from('customers')
          .update(customer.toInsert())
          .eq('id', customer.id!)
          .select()
          .single();
      return Customer.fromMap(row);
    }
    final rows = await _client
        .from('customers')
        .upsert(customer.toInsert(), onConflict: 'document')
        .select()
        .limit(1);
    return Customer.fromMap(rows.single);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}
