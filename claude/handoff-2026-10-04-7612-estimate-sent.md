# Handoff 2026-10-04 — 7612 Hillside Dr: запрос на расчёт отправлен Элде

## Executive summary
- **Письмо Элде отправлено** 2026-10-04 (Андрей, без изменений): «7612 Hillside Dr — Request for Estimate (Cesar kitchen and pantry)».
  - To: elda@dzineelements.com.
  - Cc: learco.bolletta@cesar.it, g@dzineelements.com.
  - Вложения: `7612_Hillside_Dr_Drawings_v1.6.pdf` (19 листов) и `7612_Hillside_Dr_Kitchen_Preliminary_Model_v0_4_order.csv`.
- **Статус:** FOR ESTIMATE ONLY. Ничего не заказывается до retainer клиента.
- **Ждём** Metron-расчёт от Элды и ответы на вопросы.
- **Следующий шаг кода:** commit писателя LayOut. Остальное — по ответу Элды.

## Состояние файлов
| Что | Где | Статус |
|---|---|---|
| Модель | `~/Documents/7612_Hillside_Dr_Kitchen_Preliminary_Model_v0.4.skp` | сохранена 16:19 PDT (probe 350s), после probe 349 |
| Комплект LayOut | `~/Documents/7612_Hillside_Dr_Drawings_v1.6.layout` и `.pdf` | отправлен |
| CSV заказа | `~/Documents/7612_Hillside_Dr_Kitchen_Preliminary_Model_v0_4_order.csv` | 165 строк, отправлен |
| Поля штампа | `~/Documents/7612_Hillside_Dr_sheet_fields.json` | rev 0.1 For estimate |
| Писатель | `tools/layout/ucon_sheet_template.rb`, `tools/layout/ucon_drawing_set.rb` | **не закоммичены** |
| Probe последней сборки | `tools/probe_inbox/done/24_353_7612_drawing_set_v1_6.rb` | git-ignored; это рецепт для пересборки |
| Вопросы | `docs/Elda_Open_Questions_v0.1.md` | дописан раздел «SENT» и Q52 |

## Комплект v1.6 — состав
- G-000 Cover, G-001 Legend.
- A-101 Top View, A-102 Top View — Dimensions.
- A-201…A-205 — развёртки A–E.
- A-206 / A-207 — остров.
- A-601 — 3D.
- K-101 / K-102 — схемы номеров; кастомные позиции красные.
- A-701 / A-702 — Cabinet Schedule.
- A-703 — Custom / To Quote (красным).
- A-704 — Appliance Schedule.
- A-705 — Order Form Maxima 2.2.

## Решения Андрея, принятые в этой сессии
- Размеры только в мм. Масштаб 1/2″. Остров на 2 листах.
- Backsplash:
  - кухня — Dekton 1,2 см, считает Cesar, 920 → 1465 (2 × 1773 × 545);
  - кладовая — 12 мм by others, 922 → 1467.
- Штриховка камня — Terrazzo.
- D1, проходная дверь в кладовую: **pivot**, Cesar проверяет и предлагает варианты (Q36).
- Приборы: Thermador и посудомойка Dacor DDW24G9000AP (sliding hinge). Всё поставляет **клиент**: приборы, мойку, смеситель.
- Форма заказа:
  - каркас Grigio Fumo;
  - Legrabox stainless;
  - gola, цоколь H.6 и кромка навесных — чёрный алюминий;
  - кромка столешницы прямая;
  - код клиента назначит Cesar (3-й проект UCON с Cesar);
  - доставка Port of Long Beach, дата не определена.

## Что спрошено у Элды
Q34.3, Q35, Q36 (pivot), Q37, Q39, Q40, Q41, Q42 (+ backsplash), Q43, Q44, Q47–Q50 и **Q52** (inside grip edging для jumbo-ящиков).
Не спрошены: Q38, Q45 (снят), Q51.

## Техника, найденная в сессии
- **Probe может сохранить модель сам:** `m.save` внутри probe (350s). Файл на диске получает состояние на момент сохранения; abort_operation моста после этого ничего не откатывает на диске. Перед сохранением сверять сцены по числу скрытых объектов.
- **LayOut читает .skp с диска.** Несохранённые правки сцен в комплект не попадают — проверять `File.mtime(m.path)` против времени write-probe.
- **Порядок слоёв LayOut** = порядок создания. Слой Views создаётся после Sheet и лежит над ним. Подложка под надписи — на отдельном слое Notes, который создаётся после первого вида (`note_text` в `ucon_drawing_set.rb`).
- `table_pages`: ячейка максимум 2 строки, обрезка по `fit` (0,58 × кегль). Длинные значения разбивать `\n` заранее.
- **Вложения в Gmail-черновик:** коннектор Gmail принимает файл только base64 внутри запроса, для PDF 1,3 МБ это непрактично. Рабочий путь:
  1. текст — через `update_draft`;
  2. файлы — через Chrome, `file_upload` в input черновика с путём `/mnt/user-data/uploads/...` (после `device_stage_files`). Пути на маке и в outputs отклоняются.

## Commit (делает Андрей)
`build/go.sh` и `build/commit-msg.txt` подготовлены. Staged будет 4 файла:
1. `tools/layout/ucon_sheet_template.rb`
2. `tools/layout/ucon_drawing_set.rb`
3. `docs/Elda_Open_Questions_v0.1.md`
4. `claude/handoff-2026-10-04-7612-estimate-sent.md`

(`build/go.sh` тоже в списке, но staged попадёт, только если изменён.)

## Мусор (удаляет Андрей)
- `~/Documents/7612_Hillside_Dr_Drawings_v0.1.*`, `v0.2.*`, `v0.4.*`, `v0.4.1.*`, `v0.4.2.*`, `v0.4.3.*`, `v1.4.*`, `v1.5.*`
- `~/Documents/UCON_Sheet_Template_11x17_v1.*`, `v1.1.*`, `v1.2.*`
- `~/Documents/_font_test_324.pdf`, `~/Documents/7612_dim_proof_ElevB_v0.1.*`
- `build/7612_Hillside_Dr_Kitchen_Preliminary_Model_v0_4_order.csv`
- `tools/probe_inbox/350_7612_drawing_set_v1_3.rb.hold`, `341_7612_drawing_set_v0_5.rb.unused`

## Дальше
1. Commit (выше).
2. Ответ Элды:
   - разнести Metron-расчёт против CSV — сверка кодов, как в 545;
   - по ответам на Q36 / Q40 / Q41 / Q39 — правка модели и rev 0.2 комплекта.
3. Когда понадобятся ещё проекты в LayOut — вынести 7612-специфику из probe 353 (`door_note`, `@extra_marks`, `appl`, `form`) в данные проекта (json рядом с `sheet_fields`).
