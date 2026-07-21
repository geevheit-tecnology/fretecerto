import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/fretecerto_app.dart';

void main() {
  runApp(const FreteCertoAppBootstrap());
}

class FreteCertoAppBootstrap extends StatelessWidget {
  const FreteCertoAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: FreteCertoApp());
  }
}
