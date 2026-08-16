# Elda First Pass Questions Package v0.1

**Project:** Cesar Dealership / UCON Cabinet Supply System  
**Prepared by:** UCON Contemporary Interiors  
**Document status:** First-pass workflow confirmation package  
**Source basis:** Current Project Sources only  

## 1. Purpose of This Question Package

UCON has created a preliminary, source-based Cesar planning library using the technical catalogs, controlled extraction workbooks, and internal source-governance documents currently available to us.

The library is intended to support preliminary SketchUp planning, technical review, and preparation of pilot quote-request packages. It is not production-ready and does not confirm current product availability, U.S. applicability, commercial conversion rules, final pricing, or order-release requirements.

The purpose of this first-pass package is to confirm the commercial and technical workflow before UCON uses the planning library for pilot quote requests or develops reusable SketchUp components. This is not a request to review the full consolidated questions register or validate every extracted row.

## 2. Short Context for Elda / Giorgio

UCON is preparing a controlled preliminary Cesar planning workflow for a potential pilot project and broader dealership feasibility review.

At this stage, we are not asking Elda, Giorgio, DzineElements, or Cesar to review every module, dimension, or technical question in the planning library. The immediate objective is to clarify the first decision gates:

- which technical sources currently govern U.S. work;
- how commercial terms and price-list references are applied;
- how responsibilities are divided among UCON, DzineElements, Cesar, and other parties;
- which software, quotation, revision, and order workflow must be used;
- what information is required for a formal quote request;
- which U.S.-specific, lighting, and Linear Elements limitations must be resolved first;
- what approvals separate a preliminary placeholder from quote-ready or order-ready information.

Once these gates are confirmed, UCON can organize the remaining detailed questions into focused technical review packages rather than sending the full 118-question register at once.

## 3. First-Pass Questions Table

### `Elda_First_Pass_Questions_v0.1`

| Question # | Category | Question | Why it matters | Blocks | Requested answer format | Owner suggested | Priority | Source basis / Register ID if available |
|---:|---|---|---|---|---|---|---|---|
| 1 | A. Current source authority and U.S. applicability | Please confirm which Cesar technical price-list editions and product schedules are the current authority for U.S. kitchen and Linear Elements orders, and identify any superseding U.S.-specific manuals. | The current source PDFs may contain older price-list information, and catalog presence does not confirm current production availability. | Quote Request / Pricing / Order | Current authoritative document list, including edition/date and any U.S.-specific supplements | Elda | Critical | `EQ-004`; `Current_Source_System_Status_v0.3.md`, Sections 3, 8, and 9 |
| 2 | B. Commercial terms / coefficient / price-list use | Please provide the current dealer purchasing coefficient, applicable price list, currency basis, and rules for converting catalog points or price groups into a DzineElements purchase quotation. | The planning library retains points and price groups only as references and does not establish commercial conversion logic. | Pricing / Order | Current price list, coefficient, currency basis, and written conversion procedure | DzineElements commercial | Critical | `EQ-002`; `Current_Source_System_Status_v0.3.md`, Sections 8–10 |
| 3 | C. Responsibility split | Please confirm the commercial responsibility split for freight, tariffs, tax, delivery, damage and shortage claims, lead time, field measurement, appliance verification, technical review, installation, and warranty. | Pilot economics, landed cost, contract scope, and risk allocation cannot be evaluated until responsibilities are assigned. | Pricing / Order / Installation | Written responsibility matrix by activity and responsible party | DzineElements commercial | Critical | `EQ-003`; `Current_Source_System_Status_v0.3.md`, Section 8 |
| 4 | D. Software / quoting workflow | Which software platform must UCON use for Cesar configuration, quotation, technical validation, order submission, and revision control? What access, training, catalog updates, and support will DzineElements provide? | The required software and validation environment are not established in the current planning system. | Quote Request / Pricing / Order | Software name, access process, training path, update process, and support contact | Giorgio | Critical | `EQ-013`; `Current_Source_System_Status_v0.3.md`, Section 9 |
| 5 | E. Final order workflow | Please provide the final order workflow from preliminary layout through technical review, quotation, revision approval, signed order, deposit, production release, acknowledgment, and change control, including the responsible party at each gate. | The current planning system is explicitly not a production-order system. | Order | Written stage-gate workflow or process diagram with owners and required approvals | Giorgio | Critical | `EQ-007`; `Current_Source_System_Status_v0.3.md`, Sections 1, 9, 10, and 11 |
| 6 | F. Minimum quote-request package | Please define the minimum documentation package required for a formal quote request, including plan and elevation files, module schedule, finishes, appliance data, modifications, Linear Elements drawings, lighting loads, and project assumptions. | UCON needs a controlled intake standard before submitting pilot quote requests. | Quote Request / Pricing | Checklist or sample approved quote-request package | Giorgio | Critical | `EQ-008`; `Current_Source_System_Status_v0.3.md`, Sections 1, 9, and 10 |
| 7 | G. USA Elements authority | Please confirm whether the USA Elements pages currently available to UCON are the technical ordering authority for the U.S. market or whether a separate current USA technical manual is required. | The USA Elements extract is suitable only for preliminary planning until its authority and currency are confirmed. | SketchUp / Quote Request / Order | Written confirmation plus current USA manual or schedule, if separate | Elda | Critical | `EQ-014`; `USA_Elements_Source_Extract_v0.1(1).xlsx`, Elda Questions — Production authority of the USA Elements section |
| 8 | H. Lighting / U.S. electrical compatibility | Please confirm the correct U.S. solution for the luminous glass shelf because its 50 W power-adapter kit is marked unavailable in 110 V. | The listed shelf cannot be treated as U.S.-compatible without an approved alternative. | SketchUp / Quote Request / Order / Installation | Approved U.S. configuration or written confirmation that no U.S. solution is available | Cesar technical office | Critical | `EQ-010`; `Lighting_Source_Extract_v0.1.xlsx`, Elda Questions — Luminous glass shelf |
| 9 | H. Lighting / U.S. electrical compatibility | Please confirm the applicable U.S. electrical listing or certification and the required electrician scope for transformers, distributors, sensors, and cable connections. | U.S. compliance and trade responsibility cannot be inferred from the catalog. | SketchUp / Quote Request / Order / Installation | Certification references, approved U.S. components, and electrician-scope statement | Cesar technical office | Critical | `EQ-011`; `Lighting_Source_Extract_v0.1.xlsx`, Elda Questions — Entire lighting system |
| 10 | I. Linear Elements feasibility and U.S. availability | Which Linear Elements families and finish groups are currently orderable for the U.S. market? | The Linear Elements workbook confirms catalog content, not current U.S. availability. | SketchUp / Quote Request / Order | Written availability matrix by family and finish group, or identification of the controlling current source | Cesar technical office | High | `EQ-032`; `Linear_Elements_Source_Extract_v0.1.xlsx`, Elda Questions |
| 11 | I. Linear Elements feasibility and U.S. availability | Which sink, hob, cutout, seam, joint, and support conditions require Cesar factory engineering rather than field fabrication or standard quote processing? | Linear Elements feasibility cannot be determined from nominal dimensions alone. | SketchUp / Quote Request / Order / Installation | Technical rule summary and required engineering-submittal triggers | Cesar technical office | High | `EQ-036`; `Linear_Elements_Source_Extract_v0.1.xlsx`, Elda Questions |
| 12 | J. Production-status boundaries | Please define the written approvals required to change an item from preliminary placeholder to quote-ready, pricing-ready, order-ready, and installation-ready status. | The source system separates preliminary planning from commercial, production, and installation authorization. | SketchUp / Quote Request / Pricing / Order / Installation | Stage definitions, approval owner, and required evidence for each status | Giorgio | Critical | `EQ-012`; `Current_Source_System_Status_v0.3.md`, Sections 1, 10, and 11 |
| 13 | K. SketchUp placeholder / source metadata rules | Please confirm whether UCON should retain neutral internal placeholder IDs in SketchUp until current item codes and configurations are approved, and define the source metadata that must be attached to each placeholder. | Reusable components must not be mistaken for approved Cesar modules or lose traceability to their source and confirmation status. | SketchUp / Quote Request | Written naming and metadata standard | Elda | High | `EQ-088`; `Elda_Questions_Register_v0.1.xlsx`; supported by `P1_Component_Build_List_v0.1.xlsx` release controls |
| 14 | K. SketchUp placeholder / source metadata rules | Should component-library references retain historic catalog prefixes such as PB, PC, PD, PE, PG, PF, and PJ, or should UCON use neutral internal placeholder IDs until current codes are confirmed? | Historic or unconfirmed references could be misread as current orderable item codes. | SketchUp / Quote Request / Order | Written component-ID rule with one approved example | Cesar technical office | High | `EQ-096`; `Elda_Questions_Register_v0.1.xlsx`; supported by `P1_Component_Build_List_v0.1.xlsx` production-status controls |

## 4. Questions Intentionally Deferred

| Deferred category | Why deferred | When to address later |
|---|---|---|
| Detailed base-unit matrices | The first discussion should confirm source authority, software, quote workflow, and production boundaries before requesting exact width-by-depth-by-front matrices. | After the current U.S. source authority and quote-request workflow are confirmed; prioritize rows required by the pilot. |
| Detailed wall-unit matrices | Exact opening, width, depth, fixing, hood, and collection combinations are too detailed for the first workflow discussion. | During a focused wall-unit technical review after pilot layout requirements are known. |
| Detailed tall-unit matrices | Exact appliance-stack, height, depth, and collection combinations require appliance-specific and current-availability review. | After the pilot appliance schedule is fixed and the current USA/tall-unit authority is confirmed. |
| Modifications / customisations matrix | Modification feasibility depends on the governing catalog, technical review path, commercial treatment, and production approval rules. | After the software, quotation, technical-review, and order-release workflow is confirmed. |
| Detailed lighting component matrix | The first gate is U.S. compatibility, certification, and electrician responsibility; detailed lamp-driver-cable combinations follow afterward. | After Cesar confirms the approved U.S. lighting architecture and controlling components. |
| Full Linear Elements SKU extraction | A full SKU system would add complexity before current U.S. availability and factory-engineering boundaries are known. | After U.S. availability, finish families, feasibility-review triggers, and quoting workflow are confirmed. |
| Full accessory / mechanism compatibility | Compatibility questions are module-specific and should not delay the first commercial and workflow decisions. | During project-specific technical review once the pilot module families and opening systems are selected. |
| Appliance-specific cabinet compatibility | Final compatibility requires confirmed appliance models, manufacturer cut sheets, current cabinet schedules, and Cesar technical review. | After the pilot appliance schedule and minimum quote-request package are established. |
| Final pricing | The current library contains reference points and price groups only; coefficient, currency, freight, tariffs, tax, margin, and responsibilities are unresolved. | After commercial terms and landed-cost responsibilities are confirmed in writing. |
| Production order schedule | The current planning system does not authorize ordering or production release. | After technical review, quotation approval, signed order, deposit, production-release criteria, and change-control workflow are confirmed. |

## 5. Suggested Meeting Structure

1. **10 minutes — Source authority and U.S. applicability**  
   Confirm controlling catalogs, current editions, U.S.-specific manuals, USA Elements authority, and current availability boundaries.

2. **15 minutes — Commercial terms, coefficient, and responsibility split**  
   Confirm purchasing coefficient, price-list use, currency basis, freight, tariffs, tax, delivery, claims, warranty, and scope ownership.

3. **15 minutes — Software, quoting, and order workflow**  
   Confirm required platform, access and training, quote-request intake, revision control, technical validation, approvals, and production release.

4. **15 minutes — First technical gates**  
   Confirm U.S. lighting compatibility, Linear Elements availability and engineering boundaries, USA Elements authority, and placeholder rules.

5. **5 minutes — Next documents and next review**  
   Agree who will provide each document or answer, target sequence, and which detailed technical package should be reviewed next.

## 6. Suggested Email Text

**Subject:** Cesar Preliminary Planning Workflow — First-Pass Questions

Hi Elda and Giorgio,

UCON has organized the Cesar technical materials currently available to us into a preliminary source-based planning library for SketchUp planning and future pilot quote requests.

The library is not production-ready, and we are not asking you to review every extracted row or detailed technical question at this stage. Before we use it for a pilot quote request or build reusable SketchUp components, we would like to confirm the first workflow gates: the current U.S. source authority, commercial terms and responsibility split, required software and quoting process, final order workflow, and several key U.S. technical limitations.

Attached is a concise first-pass package with 14 questions. The objective is to avoid incorrect assumptions and prevent mistakes before any pricing, ordering, or client commitments are made.

A 60-minute working session should be sufficient to identify the correct documents, responsible parties, and next technical review package.

Thank you,

Andriy Demko  
UCON Contemporary Interiors

## 7. Production-Status Warning

> **WORKFLOW CONFIRMATION ONLY**  
> This package is for workflow confirmation only. It does not authorize pricing, ordering, fabrication, installation, or client commitments.
