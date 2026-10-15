# 7612 Hillside Dr — ванные и прачечная: комплект чертежей v0.3 (на согласование клиенту), 2026-10-14

**Файлы:** `~/Documents/7612_Hillside_Dr_Baths_Laundry_Drawings_v0.3.pdf` (14 листов, 933 170 байт) и `.layout`.
Собирает probe 694 (`tools/probe_inbox/done/*694*`) инструментом `tools/layout/bath_drawing_set.rb` поверх `ucon_drawing_set.rb` (тот же шаблон 11×17, что у кухни).

## Решения Андрея
- Назначение: **клиенту на согласование** (статус FOR CLIENT APPROVAL, поле подписи в штампе и на обложке).
- Прачечная — в этом же комплекте.
- На комнату: план + фасад + 3D.

## Состав
G-000 обложка (3D мастер-ванной) · G-001 перечень листов + общие примечания (отделки) · по два листа на комнату:
A-101…A-106 **PLAN & 3D** (план 1/2" = 1'-0" с размерами + 3D), A-201…A-206 **ELEVATION** (фасад 1/2" с размерами).
Комнаты: Powder Room, Guest Bath, Master Bath, Bath 2, Bath 3, Laundry.

## Как устроено
- Сцены в моделях: `<R> Plan / <R> Elevation / <R> ISO` — ванные probe 687 (+688 ISO по размеру), прачечная probe 690. Стиль «UCON CAD», как кухня (probe 294).
- Фасад ванной — свой (`bath_elevation`): ряд тумб от стены до стены (полоски и зазоры видны как отрезки), ряд зеркал сверху, высоты: низ тумб 243, верх корпуса 828, столешница 850 (столик 765), зеркало 1250–1950, пенал/потолок. Прачечная — кухонной логикой (`elevation`).
- План — `bath_plan`: ряд по фасадам тумб + глубины (тумбы 495, пенал 645).
- Два листа на комнату, потому что фасад M-BA1 до потолка с рядами размеров ~7″ и вместе с планом не помещается.
- Размеров 142, все привязаны к модели.

## Мусор (удаляет Андрей)
- `~/Documents/7612_Hillside_Dr_Baths_Laundry_Drawings_v0.1.*` (планы не влезли — STOP на листах) и `_v0.2.*` (длинные названия вылезали из штампа).

## Дальше
- Замечания Андрея по листам → v0.4.
- Отправка клиенту — отдельным шагом.


## v0.4 (2026-10-14, later the same day)

Andriy on v0.3: sheet 8/14 cut the room height; a pouf under the make-up station, scale figures (women too) — "это в layout"; a shower on 10/14 on the right. All done in LayOut, the model is not touched (probe 696, which would have put them into the model, was refused and then stopped by Andriy).

- **Ceilings** passed for every room (PWD 3043, BA1 2716, MST 3034, BA2 2055, BA3 2055): elevations now run floor to ceiling with the ceiling level dimensioned.
- **Scale figures:** the LayOut scrapbook "People" (SketchUp 2025, row 1 Detailed) has no groups — 12 figures as loose paths. Dumped by read-only probe 697d, three picked (woman_a, woman_b, man_a), normalised to height in `tools/layout/scale_figures.json` and re-drawn as grey outlines (no fill, so the cabinets stay readable) at 1650 / 1780 mm. Tag "Entourage", one group per figure — movable by hand in LayOut. **Placed OUTSIDE the drawing** (Andriy: in front of the vanities they cluttered it): to the right of the height dimensions, on the floor line, with a short ground line; the elevation shifts left to make room (probe 698c).
- **Pouf** M-MST: D450 H430 at room x 2208, under the make-up table; elevation rounded body + label, plan dashed circle.
- **Shower** L-BA2: glass edge at 2277, wall head, valve, drain, note "glass & fixtures by others"; 2277 stop in the plan and elevation chains (159 | 1168). The scrapbooks have no shower or furniture — drawn by hand. If "из песочницы" meant a specific source file, say which.
- Output `~/Documents/7612_Hillside_Dr_Baths_Laundry_Drawings_v0.4.layout` + `.pdf` (probe 698b). Earlier v0.4 runs moved to `~/Documents/_to_delete/`.
- Junk for Andriy: `~/Documents/_to_delete/`, Drawings v0.1 / v0.2, `tools/layout/people_scrapbook_raw.json` (raw dump, not committed).
