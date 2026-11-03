# Compromissos do Calendário — Aula 7

Programação para Dispositivos Móveis I — Prof. Arley — Fatec

## Integrantes

- Carlos Santo

## Sobre

Aplicativo Flutter (Android) que consulta o calendário do aparelho e lista os
compromissos de hoje e dos próximos seis dias (sete dias no total).

- Pede a permissão de acesso ao calendário quando o usuário toca em
  **Consultar compromissos**.
- Consulta **todos** os calendários do aparelho (Google, Samsung, feriados etc.).
- Lista os compromissos em ordem cronológica, agrupados por dia.
- Mostra, para cada um: título, calendário, data e horário de início e fim, local
  e descrição.
- Marca com o selo **Dia inteiro** os compromissos que ocupam o dia todo.
- Mostra um indicador de carregamento durante a consulta e bloqueia o botão para
  evitar consultas duplicadas.
- Informa quando não há compromissos, quando o acesso é negado e quando a consulta
  falha (inclusive quando só alguns calendários não puderam ser lidos).

### Permissões (Android)

Declaradas em `android/app/src/main/AndroidManifest.xml`:

| Permissão | Motivo |
| --- | --- |
| `READ_CALENDAR` | Ler os compromissos |
| `WRITE_CALENDAR` | O `device_calendar` pede leitura e escrita juntas e só considera o acesso autorizado com as duas |

O app não cria nem altera compromissos.

## Baixar o APK

O APK é gerado automaticamente pelo GitHub Actions a cada push, então não é preciso
ter o Android SDK instalado para testar o app.

1. Abra a aba [Actions](https://github.com/Carlos-Santo/atividade-7/actions/workflows/build-apk.yml)
   e clique na execução mais recente com ✅.
2. No fim da página, em **Artifacts**, baixe **compromissos-apk** (é preciso estar logado no GitHub).
3. Extraia o `.zip` e instale o `app-release.apk` no celular Android, permitindo a
   instalação de fontes desconhecidas.

Se o artefato tiver expirado (ficam disponíveis por 90 dias), use **Run workflow** na
mesma página para gerar um novo.

## Como executar

```bash
flutter pub get
flutter run   # precisa de um aparelho ou emulador Android
flutter test  # testes com o calendário simulado
```

## Estrutura

```
lib/
├── main.dart
├── models/compromisso.dart              # dados de um compromisso já prontos para exibir
├── services/servico_calendario.dart     # permissão e consulta pelo device_calendar
└── telas/tela_compromissos.dart         # botão, mensagens e lista agrupada por dia
```

## Pacotes

| Pacote | Uso |
| --- | --- |
| device_calendar | Permissão e leitura dos calendários e eventos |
| intl | Formatação de datas em português |
