# O R8 (que encolhe e renomeia o código no APK de release) renomeia os campos
# das classes do device_calendar. O plugin converte essas classes em JSON com o
# Gson, então os nomes mudam ("id" vira "a"...) e o retrieveCalendars() devolve
# calendários sem id. Esta regra mantém as classes do plugin intactas.
# Ver: https://github.com/builttoroam/device_calendar/issues/99
-keep class com.builttoroam.devicecalendar.** { *; }
