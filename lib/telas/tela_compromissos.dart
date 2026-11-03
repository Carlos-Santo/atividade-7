import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/compromisso.dart';
import '../services/servico_calendario.dart';

class TelaCompromissos extends StatefulWidget {
  const TelaCompromissos({super.key});

  @override
  State<TelaCompromissos> createState() => _TelaCompromissosState();
}

class _TelaCompromissosState extends State<TelaCompromissos> {
  final ServicoCalendario _servico = ServicoCalendario();

  List<Compromisso> _compromissos = [];
  bool _carregando = false;
  bool _erro = false;
  String _mensagem =
      'Pressione o botão para consultar os compromissos de hoje '
      'e dos próximos seis dias.';

  Future<void> _consultar() async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
      _erro = false;
      _compromissos = [];
      _mensagem = 'Consultando o calendário...';
    });

    try {
      final resultado = await _servico.consultarProximosSeteDias();
      if (!mounted) return;

      setState(() {
        switch (resultado.situacao) {
          case SituacaoConsulta.acessoNegado:
            _erro = true;
            _mensagem =
                'O acesso ao calendário não foi autorizado. Se a permissão '
                'foi bloqueada, libere "Agenda" nas configurações do '
                'aplicativo e tente novamente.';
          case SituacaoConsulta.falha:
            _erro = true;
            _mensagem = 'Não foi possível consultar o calendário.';
          case SituacaoConsulta.sucesso:
            _compromissos = resultado.compromissos;
            _mensagem = _resumo(resultado);
        }
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _mensagem = 'Ocorreu uma falha ao consultar o calendário.';
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  String _resumo(ResultadoConsulta resultado) {
    final total = resultado.compromissos.length;
    final calendarios = resultado.totalCalendarios;

    var texto = calendarios == 0
        ? 'Nenhum calendário encontrado no dispositivo.'
        : total == 0
        ? 'Nenhum compromisso nos próximos sete dias '
              '($calendarios calendário(s) consultado(s)).'
        : '$total compromisso(s) em $calendarios calendário(s).';

    if (resultado.calendariosComFalha.isNotEmpty) {
      texto +=
          '\nNão foi possível ler: '
          '${resultado.calendariosComFalha.join(', ')}.';
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Compromissos da semana')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: _carregando ? null : _consultar,
              icon: const Icon(Icons.event),
              label: const Text('Consultar compromissos'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _mensagem,
              style: TextStyle(color: _erro ? cores.error : null),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _ListaCompromissos(compromissos: _compromissos),
          ),
        ],
      ),
    );
  }
}

/// Lista agrupada por dia, com um cabeçalho para cada data.
class _ListaCompromissos extends StatelessWidget {
  final List<Compromisso> compromissos;

  const _ListaCompromissos({required this.compromissos});

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final itens = <Widget>[];
    DateTime? diaAtual;

    for (final compromisso in compromissos) {
      var dia = DateTime(
        compromisso.inicio.year,
        compromisso.inicio.month,
        compromisso.inicio.day,
      );
      // Compromissos que começaram antes de hoje e ainda estão em andamento.
      if (dia.isBefore(hoje)) dia = hoje;

      if (dia != diaAtual) {
        diaAtual = dia;
        itens.add(_CabecalhoDia(dia: dia, hoje: hoje));
      }
      itens.add(_CartaoCompromisso(compromisso: compromisso));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: itens,
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  final DateTime dia;
  final DateTime hoje;

  const _CabecalhoDia({required this.dia, required this.hoje});

  @override
  Widget build(BuildContext context) {
    final diferenca = dia.difference(hoje).inDays;
    final data = DateFormat("EEEE, dd/MM", 'pt_BR').format(dia);
    final rotulo = switch (diferenca) {
      0 => 'Hoje — $data',
      1 => 'Amanhã — $data',
      _ => data[0].toUpperCase() + data.substring(1),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        rotulo,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CartaoCompromisso extends StatelessWidget {
  final Compromisso compromisso;

  const _CartaoCompromisso({required this.compromisso});

  static final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  String _periodo() {
    final c = compromisso;
    if (c.diaInteiro) {
      final mesmoDia = DateUtils.isSameDay(c.inicio, c.fim);
      return mesmoDia
          ? _data.format(c.inicio)
          : '${_data.format(c.inicio)} a ${_data.format(c.fim)}';
    }
    final fim = DateUtils.isSameDay(c.inicio, c.fim)
        ? DateFormat('HH:mm').format(c.fim)
        : _dataHora.format(c.fim);
    return 'Início: ${_dataHora.format(c.inicio)}\nFim: $fim';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = compromisso;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    c.titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (c.diaInteiro)
                  Chip(
                    label: const Text('Dia inteiro'),
                    avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: tema.colorScheme.secondaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Linha(icone: Icons.calendar_month, texto: c.calendario),
            _Linha(icone: Icons.schedule, texto: _periodo()),
            _Linha(
              icone: Icons.place_outlined,
              texto: c.local ?? 'Local não informado',
              apagado: c.local == null,
            ),
            _Linha(
              icone: Icons.notes,
              texto: c.descricao ?? 'Sem descrição',
              apagado: c.descricao == null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool apagado;

  const _Linha({
    required this.icone,
    required this.texto,
    this.apagado = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = apagado ? Theme.of(context).disabledColor : null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(color: cor)),
          ),
        ],
      ),
    );
  }
}
