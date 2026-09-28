# Cesar collections: Maxima, Intarsio, Unit, N_Elle - recon (2026-09-27)

Andriy's question: the catalog in the engine has no split into Maxima / "Elite" / other
series - do we need one, how does it enter the picker, and is it geometry or finish?

## What the books print
- **No "Elite" collection exists.** Project Guidelines printed p.41 (Collections index):
  Intarsio (42), Maxima 2.2 (50), Tangram (105), Unit (125), N_Elle (160), Glass display
  cabinet (200). The closest name is N_Elle.
- **Price bands, PG printed p.12-13:** one table, five columns - UNIT, MAXIMA 2.2, TANGRAM,
  INTARSIO, N_ELLE, all th. 2.2. The band (the price column 1-11 in Kitchen System) is
  finish x collection x grip edging / door type. Example: silk-effect lacquer = band 4 on
  Maxima, 8 on Intarsio, 6 on N_Elle; Shaker door 6, Groove door 8.
- **Kitchen System general index (printed p.3):** Maxima e Intarsio (19), Tangram (57),
  Unit (257), N_Elle (321), N_Elle with framed door (397), USA elements (409).

## Two kinds of "collection"
| collection | own chapter and codes in Kitchen System | carcass geometry | kind |
|---|---|---|---|
| Maxima 2.2 | shared with Intarsio, p.19-56, one code table (BL0601...) | the same | door / finish |
| Intarsio | shared with Maxima; pages carry both marks | the same | door / finish |
| Maxima door types: Maxima, Shaker, Framed (18 alu + 4), Groove | no - finish pages PG p.51-52 | the same, all 22 mm | door / finish |
| Tangram | own, p.57-62 | curved | geometry - done |
| Unit | own, p.257-304: aluminium-frame side panels TSN/TSI, H.66 / H.72 | different | geometry |
| N_Elle (+ framed door) | own, p.321-408, heights 36,8 / 78 / 84, door 80,2 | different | geometry |

So "collection" is two things. **Maxima vs Intarsio** (and the Maxima door types) is a
DOOR/FINISH choice on the same article - it changes the price column and the allowed opening
methods (Intarsio: no step / 30 deg / inside grip edging, PG p.43 against p.51), not the
drawing. **Unit and N_Elle** are separate catalogs with their own codes and heights - geometry,
the same way Tangram is.

## Consequences for the engine
1. Picker (places the article = geometry): a collection becomes a top-level chapter ONLY when
   the book prints it with its own codes - as Tangram already is. Today: "Maxima e Intarsio"
   (current Base / Wall / Tall), "Tangram". Later, when a project needs them: "Unit", "N_Elle".
   Maxima and Intarsio are NOT two picker entries: the same BL0601 in both.
2. Door model / collection (Maxima 2.2 / Intarsio / Shaker / Groove / Framed) belongs with
   the finish: an order-level default with an override per element (the order form asks
   mixed finishes "for each single element", PG p.65). It sets the price column and filters
   the panel's opening options. That is the open proposal docs/Finish_In_The_Model_v0.1.md.
3. Contract: `collection` already exists (v2 table), written only by Tangram. Box units do
   not write it yet.
4. Not urgent for drawing: nothing in 7612 changes (Maxima + Tangram). Needed for pricing and
   the order form - with the finish work.
