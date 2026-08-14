import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/fretecerto_app.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const FreteCertoAppBootstrap());
}

class FreteCertoAppBootstrap extends StatelessWidget {
  const FreteCertoAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: FreteCertoApp());
  }
}
