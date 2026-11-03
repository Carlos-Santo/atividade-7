import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'telas/tela_compromissos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nomes dos dias da semana em português (ex.: "quarta-feira").
  await initializeDateFormatting('pt_BR');
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Compromissos',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TelaCompromissos(),
    );
  }
}
