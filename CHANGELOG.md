# Changelog

## 3.0.0 — 2026-09-19
* LXRCore v3 release line: every resource ships as 3.0.0 from here (the entries below are the road to it).

## 3.1.0 — 2026-09-18

* The counter rebuilt as a Vite + React bundle on the kit: shelves as a category list with counts, item cards with pictures from the inventory icon set, stock badges, search, Buy / Sell / Purchases tabs, a basket with per-line steppers, and a choice of purse (cash or bank — `Config.Trade.accounts`)
* `lxr-shops:buy` takes the purse; the counter payload carries `purses` and `accounts`

## 3.0.0 — 2026-09-17

Rebuilt on the LXRCore v3 native API. Nothing of the earlier multi-framework build remains; store positions were kept as data.

* Shelves as catalog filters, prices from the 1899 ledger with per-store mark-ups, night mark-up
* Buying with a validated cart and one charge; selling by quality at a share of the ledger value
* Optional limited stock with restocking, persisted
* Clerks as lxr-interact targets, blips per kind, staff-only counters
* Counter page on the LXR UI Kit, locales EN / KA, offline tests
