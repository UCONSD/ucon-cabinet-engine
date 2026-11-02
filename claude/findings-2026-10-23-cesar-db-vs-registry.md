# Findings 2026-10-23 — реестр движка против базы Cesar (снапшот Metron)

Уровень: CONTROL. Только чтение. Снапшот `~/dev/ucon-cesar/cesar_snapshot.sqlite`, выгружен 2026-10-23 08:40 с JULIAIAPTOP. Ничего в `registry/` не менялось.

## Итог

- Кодов в реестре: 1673. Есть в базе: 1544. Нет в базе: 129.
- Ванная линия (BA*, LVB*, PLT*) в базе отсутствует целиком — это не ошибки реестра, а другой каталог/другая база. Зеркала UCON-MIR-* — собственные коды UCON, их в базе быть не должно.
- Вероятные опечатки транскрипции (в базе есть почти такой же код): F90205 → F90250, CRM550 → CRMS50, C9H550 → C9HS50. Не исправлено: решение по domain rule 1 (сверка с напечатанной страницей).
- 16 кодов верхних элементов (SB0700, SC/SD/SE 0500–1200) в базе нет; в базе есть только SC/SD/SE 0531, 0631, 0930. Открытый вопрос: напечатаны ли они в книге и выведены ли из линейки.
- Размеры: сравнено 2985 пар (ширина/глубина/высота), различий 241. Большинство — разный смысл полей (толщина панели 22 против длины 620, номинал против диапазона), а не ошибки. Нужен отдельный проход с правилами сопоставления; выводов по ним не делать.

## Нет в базе, по файлам

- bath_base_h58_5.json (48): BA60301, BA60501, BA60601, BA40301, BA40501, BA40601, BA60600, BA60900, BA61200, BA40600, BA40900, BA41200, BA60552, BA60652, BA60752, BA60952, BA61052, BA61252, BA40552, BA40652, BA40752, BA40952, BA41052, BA41252, BA60557, BA60657, BA60757, BA60957, BA61057, BA61257, BA40557, BA40657, BA40757, BA40957, BA41057, BA41257, BA60566, BA60666, BA60766, BA60966, BA61066, BA61266, BA40566, BA40666, BA40766, BA40966, BA41066, BA41266
- bath_washbasin_h58_5.json (26): BA60661, BA40661, BA60960, BA61260, BA40960, BA41260, BA60691, BA60791, BA60991, BA61091, BA61291, BA40691, BA40791, BA40991, BA41091, BA41291, BA60687, BA60787, BA60987, BA61087, BA61287, BA40687, BA40787, BA40987, BA41087, BA41287
- bath_mirrors.json (22): UCON-MIR-RMU-070x070, UCON-MIR-RMU-120x070, UCON-MIR-RMU-060x060, UCON-MIR-RMU-080x080, UCON-MIR-RMU-100x100, UCON-MIR-RMU-120x120, UCON-MIR-RMU-060x070, UCON-MIR-RMU-090x070, UCON-MIR-RMU-100x070, UCON-MIR-ROU-D071, UCON-MIR-ROU-D085, UCON-MIR-ROU-D101, UCON-MIR-ROU-D121, UCON-MIR-ROU-D141, UCON-MIR-OVL-050x100, UCON-MIR-OVL-050x110, UCON-MIR-OVL-060x120, UCON-MIR-RIF-D070, UCON-MIR-RIF-D080, UCON-MIR-RIF-D100, UCON-MIR-RIF-D120, UCON-MIR-RIF-D140
- bath_washbasins_integrated.json (14): PLT008IX, PLT008, LVBP04.001, LVBP04.002, LVBP04.003, LVBP04.004, LVBP04.005, LVBP04.006, LVBF05.001, LVBF05.002, LVBF05.003, LVBF05.004, LVBF05.005, LVBF05.006
- tall_top_h48.json (5): SC0500, SC0600, SC0700, SC0900, SC1200
- tall_top_h60.json (5): SD0500, SD0600, SD0700, SD0900, SD1200
- tall_top_h72.json (5): SE0500, SE0600, SE0700, SE0900, SE1200
- end_open_tall_234.json (1): F90205
- hide_seek_h210.json (1): CRM550
- hide_seek_h234.json (1): C9H550
- tall_top_h36.json (1): SB0700
