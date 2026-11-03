import 'package:device_calendar/device_calendar.dart';

import '../models/compromisso.dart';

/// Situações que a tela precisa diferenciar ao consultar o calendário.
enum SituacaoConsulta { sucesso, acessoNegado, falha }

class ResultadoConsulta {
  final SituacaoConsulta situacao;
  final List<Compromisso> compromissos;
  final int totalCalendarios;

  /// Calendários cuja leitura falhou (os demais ainda são apresentados).
  final List<String> calendariosComFalha;

  const ResultadoConsulta({
    required this.situacao,
    this.compromissos = const [],
    this.totalCalendarios = 0,
    this.calendariosComFalha = const [],
  });
}

class ServicoCalendario {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// Verifica a permissão e, se ainda não houver, solicita ao usuário.
  Future<bool> garantirPermissao() async {
    final verificacao = await _plugin.hasPermissions();
    if (verificacao.isSuccess && verificacao.data == true) return true;

    final solicitacao = await _plugin.requestPermissions();
    return solicitacao.isSuccess && solicitacao.data == true;
  }

  /// Consulta os compromissos de hoje e dos próximos seis dias
  /// em todos os calendários do dispositivo.
  Future<ResultadoConsulta> consultarProximosSeteDias() async {
    if (!await garantirPermissao()) {
      return const ResultadoConsulta(situacao: SituacaoConsulta.acessoNegado);
    }

    final agora = DateTime.now();
    final inicioPeriodo = DateTime(agora.year, agora.month, agora.day);
    // Meia-noite do 7º dia seguinte: cobre hoje + 6 dias por completo.
    final fimPeriodo = DateTime(agora.year, agora.month, agora.day + 7);

    final resultadoCalendarios = await _plugin.retrieveCalendars();
    final calendarios = resultadoCalendarios.data;
    if (!resultadoCalendarios.isSuccess || calendarios == null) {
      return const ResultadoConsulta(situacao: SituacaoConsulta.falha);
    }

    final compromissos = <Compromisso>[];
    final comFalha = <String>[];

    for (final calendario in calendarios) {
      final nome = calendario.name ?? 'Calendário sem nome';
      final resultadoEventos = await _plugin.retrieveEvents(
        calendario.id,
        RetrieveEventsParams(startDate: inicioPeriodo, endDate: fimPeriodo),
      );

      final eventos = resultadoEventos.data;
      if (resultadoEventos.hasErrors || eventos == null) {
        comFalha.add(nome);
        continue;
      }

      compromissos.addAll(eventos.map((e) => Compromisso.doEvento(e, nome)));
    }

    // Se nenhum calendário pôde ser lido, a consulta como um todo falhou.
    if (calendarios.isNotEmpty && comFalha.length == calendarios.length) {
      return ResultadoConsulta(
        situacao: SituacaoConsulta.falha,
        totalCalendarios: calendarios.length,
        calendariosComFalha: comFalha,
      );
    }

    compromissos.sort(compararCompromissos);

    return ResultadoConsulta(
      situacao: SituacaoConsulta.sucesso,
      compromissos: compromissos,
      totalCalendarios: calendarios.length,
      calendariosComFalha: comFalha,
    );
  }
}

/// Ordem cronológica; no mesmo dia, os de dia inteiro aparecem primeiro.
int compararCompromissos(Compromisso a, Compromisso b) {
  final diaA = DateTime(a.inicio.year, a.inicio.month, a.inicio.day);
  final diaB = DateTime(b.inicio.year, b.inicio.month, b.inicio.day);
  final porDia = diaA.compareTo(diaB);
  if (porDia != 0) return porDia;

  if (a.diaInteiro != b.diaInteiro) return a.diaInteiro ? -1 : 1;

  final porInicio = a.inicio.compareTo(b.inicio);
  if (porInicio != 0) return porInicio;
  return a.fim.compareTo(b.fim);
}
