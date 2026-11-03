import 'package:device_calendar/device_calendar.dart';

/// Compromisso já convertido para os dados que a tela apresenta.
class Compromisso {
  final String titulo;
  final String calendario;
  final DateTime inicio;
  final DateTime fim;
  final bool diaInteiro;
  final String? local;
  final String? descricao;

  const Compromisso({
    required this.titulo,
    required this.calendario,
    required this.inicio,
    required this.fim,
    required this.diaInteiro,
    this.local,
    this.descricao,
  });

  factory Compromisso.doEvento(Event evento, String nomeCalendario) {
    final diaInteiro = evento.allDay ?? false;
    final inicio = _converter(evento.start, diaInteiro) ?? DateTime.now();
    final fim = _converter(evento.end, diaInteiro) ?? inicio;

    return Compromisso(
      titulo: _textoOuNulo(evento.title) ?? 'Sem título',
      calendario: nomeCalendario,
      inicio: inicio,
      fim: fim,
      diaInteiro: diaInteiro,
      local: _textoOuNulo(evento.location),
      descricao: _textoOuNulo(evento.description),
    );
  }

  /// Eventos com horário são convertidos para o fuso do aparelho.
  /// Eventos de dia inteiro guardam só a data (o pacote já ajusta para meia-noite
  /// do dia correto no fuso do evento), então usamos ano/mês/dia diretamente.
  static DateTime? _converter(DateTime? data, bool diaInteiro) {
    if (data == null) return null;
    if (diaInteiro) return DateTime(data.year, data.month, data.day);
    return data.toLocal();
  }

  static String? _textoOuNulo(String? texto) {
    final limpo = texto?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }
}
