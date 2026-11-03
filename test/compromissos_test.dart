import 'dart:convert';

import 'package:compromissos_calendario/main.dart';
import 'package:compromissos_calendario/models/compromisso.dart';
import 'package:compromissos_calendario/services/servico_calendario.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const canal = MethodChannel('plugins.builttoroam.com/device_calendar');

/// Simula o lado nativo do device_calendar.
void simularCalendario({
  required bool permitido,
  Map<String, List<Map<String, dynamic>>> eventosPorCalendario = const {},
  Set<String> calendariosComErro = const {},
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, (chamada) async {
        switch (chamada.method) {
          case 'hasPermissions':
          case 'requestPermissions':
            return permitido;
          case 'retrieveCalendars':
            return jsonEncode([
              for (final id in eventosPorCalendario.keys)
                {'id': id, 'name': 'Agenda $id'},
            ]);
          case 'retrieveEvents':
            final id = (chamada.arguments as Map)['calendarId'] as String;
            if (calendariosComErro.contains(id)) {
              throw PlatformException(code: 'erro');
            }
            return jsonEncode(eventosPorCalendario[id] ?? []);
        }
        return null;
      });
}

Map<String, dynamic> evento(
  String titulo,
  DateTime inicio,
  DateTime fim, {
  bool diaInteiro = false,
  String? local,
}) => {
  'eventTitle': titulo,
  'eventStartDate': inicio.millisecondsSinceEpoch,
  'eventEndDate': fim.millisecondsSinceEpoch,
  'eventAllDay': diaInteiro,
  'eventLocation': local,
  'eventDescription': null,
};

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);

  test('ordena cronologicamente com dia inteiro primeiro no mesmo dia', () {
    Compromisso c(String t, DateTime i, {bool dia = false}) => Compromisso(
      titulo: t,
      calendario: 'x',
      inicio: i,
      fim: i.add(const Duration(hours: 1)),
      diaInteiro: dia,
    );
    final lista = [
      c('amanhã 9h', hoje.add(const Duration(days: 1, hours: 9))),
      c('hoje 15h', hoje.add(const Duration(hours: 15))),
      c('hoje dia inteiro', hoje, dia: true),
      c('hoje 8h', hoje.add(const Duration(hours: 8))),
    ]..sort(compararCompromissos);

    expect(lista.map((e) => e.titulo), [
      'hoje dia inteiro',
      'hoje 8h',
      'hoje 15h',
      'amanhã 9h',
    ]);
  });

  testWidgets('informa quando o acesso é negado', (tester) async {
    simularCalendario(permitido: false);
    await tester.pumpWidget(const RootApp());
    await tester.tap(find.text('Consultar compromissos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('não foi autorizado'), findsOneWidget);
  });

  testWidgets('informa quando não há compromissos', (tester) async {
    simularCalendario(permitido: true, eventosPorCalendario: {'1': []});
    await tester.pumpWidget(const RootApp());
    await tester.tap(find.text('Consultar compromissos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum compromisso'), findsOneWidget);
  });

  testWidgets('informa falha quando nenhum calendário pode ser lido', (
    tester,
  ) async {
    simularCalendario(
      permitido: true,
      eventosPorCalendario: {'1': []},
      calendariosComErro: {'1'},
    );
    await tester.pumpWidget(const RootApp());
    await tester.tap(find.text('Consultar compromissos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível consultar o calendário.'),
      findsOneWidget,
    );
  });

  testWidgets('lista compromissos de vários calendários em ordem', (
    tester,
  ) async {
    simularCalendario(
      permitido: true,
      eventosPorCalendario: {
        '1': [
          evento(
            'Prova de PDM',
            hoje.add(const Duration(days: 1, hours: 19)),
            hoje.add(const Duration(days: 1, hours: 21)),
            local: 'Fatec',
          ),
        ],
        '2': [
          evento(
            'Feriado',
            hoje.toUtc(),
            hoje.add(const Duration(days: 1)).toUtc(),
            diaInteiro: true,
          ),
          evento(
            'Reunião',
            hoje.add(const Duration(hours: 10)),
            hoje.add(const Duration(hours: 11)),
          ),
        ],
      },
    );
    await tester.pumpWidget(const RootApp());
    await tester.tap(find.text('Consultar compromissos'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('3 compromisso(s) em 2 calendário(s)'),
      findsOneWidget,
    );
    expect(find.text('Dia inteiro'), findsOneWidget);
    expect(find.text('Fatec'), findsOneWidget);
    expect(find.text('Agenda 1'), findsOneWidget);
    expect(find.text('Agenda 2'), findsNWidgets(2));

    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Feriado'), lessThan(y('Reunião')));
    expect(y('Reunião'), lessThan(y('Prova de PDM')));
    expect(find.textContaining('Hoje'), findsOneWidget);
    expect(find.textContaining('Amanhã'), findsOneWidget);
  });
}
