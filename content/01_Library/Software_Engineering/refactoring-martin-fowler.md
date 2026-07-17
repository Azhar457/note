---
title: "Refactoring — Martin Fowler"
tags:
  - refactoring
  - martin-fowler
  - code-quality
aliases:
  - "refactoring-martin-fowler"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Refactoring = restrukturasi kode tanpa mengubah behavior. Referensi pattern dari Martin Fowler.

## Catalog (by code smell)

| Smell               | Refactoring                             |
| ------------------- | --------------------------------------- |
| Long Method         | Extract method, replace temp with query |
| Large Class         | Extract class, extract subclass         |
| Duplicated Code     | Extract method, pull up field           |
| Long Parameter List | Introduce parameter object              |
| Switch Statement    | Replace with polymorphism               |
| Feature Envy        | Move method                             |

## Workflow

1. Ensure tests exist (safety net)
2. Identify code smell
3. Apply refactoring (one at a time)
4. Run tests (green?)
5. Commit
