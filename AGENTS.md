# AGENTS.md

## Project Identity

This repository is for building the MVP of the **지지저항Lab mobile app**.

The product is a **watchlist + price-level + support/resistance signal app** for Korean retail investors.

This is **not** a full brokerage app, not a trading terminal, and not an auto-trading system.

The app's core value is:

- let users add watchlist stocks
- monitor operator-defined support/resistance levels
- calculate support state transitions
- show short explanations
- send meaningful notifications only when important state changes occur

---

## Source of Truth

Before making any code changes, you must read these documents **in order**.

1. `docs/01_지지저항Lab_앱_MVP_프로젝트개요서.md`
2. `docs/02_지지저항Lab_화면구조_사용자플로우명세서.md`
3. `docs/03_지지저항Lab_지지선상태관리_로직명세서.md`
4. `docs/04_지지저항Lab_주가데이터_수집관리_아키텍처명세서.md`
5. `docs/05_지지저항Lab_DB_API_통합명세서.md`
6. `docs/06_지지저항Lab_관리자_푸시운영명세서.md`
7. `docs/07_지지저항Lab_Flutter_FastAPI_개발순서_체크리스트.md`

These docs are the source of truth.

When implementation and assumptions conflict, follow the docs.

Do not invent major features outside these docs.

---

## MVP Scope

You must build **MVP only**.

### In scope
- stock master data
- operator-managed support/resistance levels
- support state tracking
- signal event generation
- watchlist management
- home feed
- stock search
- stock detail
- theme list
- notification list
- admin pages for stock/level/state/event management
- push notification foundations

### Out of scope for MVP
Do **not** implement these unless explicitly requested:
- payment
- subscription billing
- full community
- comments
- ranking system
- auto trading
- broker order integration
- full real-time all-market streaming
- advanced AI recommendation engine
- full social feed
- complex charting tools beyond MVP needs

---

## Repo Structure

Use this repository structure unless the repository already has a strong structure in place.

```text
/docs
/backend_api
/frontend_app
/admin_web

Expected responsibilities

backend_api: FastAPI backend, DB models, migrations, services, APIs

frontend_app: Flutter mobile app

admin_web: admin/backoffice web UI

docs: product, logic, DB/API, operations documents

Do not move or rename the documentation files unless explicitly instructed.

Tech Direction

Prefer the following stack unless the repository already uses another approved stack.

Backend

Python

FastAPI

SQLAlchemy

Alembic

PostgreSQL

Redis for cache when needed

Mobile App

Flutter

feature-based folder structure

clear separation of presentation / application / data when practical

Admin

simple web admin

can be React, Next.js, or other existing repo choice

prioritize speed and maintainability over fancy UI

Development Principles
1. Build in small phases

Never attempt to implement the entire product in one pass.

Preferred order:

backend scaffold

DB models + migrations

stock / level / support-state core logic

API layer

Flutter core screens

admin pages

notifications / push

polish / stabilization

2. Data flow first, UI second

First make the data model and core state logic correct.
Then connect APIs.
Then build UI.

3. Operator control first

For MVP, operator control is more important than full automation.

4. Prefer explicit code over clever code

Write readable, maintainable, boring code.
Avoid unnecessary abstraction early.

5. Keep docs and code aligned

When implementing something covered by docs, keep naming aligned as much as practical.

Naming and Domain Rules
Support status values

Use these support status values unless explicitly changed in docs:

WAITING

TESTING_SUPPORT

DIRECT_REBOUND_SUCCESS

BREAK_REBOUND_SUCCESS

REUSABLE

INVALID

Signal types

Use the documented signal/event naming from the docs.

UI labels

Backend may return machine-friendly code plus user-friendly label.
Do not hardcode all labels only in Flutter if the backend can provide them.

Backend Rules
Required backend priorities

When working on backend, prioritize these in order:

DB schema

domain models

support state calculation service

signal event creation

API responses shaped for screens

admin CRUD

push notification hooks

Backend architecture guidance

Prefer this structure:

backend_api/
  app/
    api/
    core/
    db/
    models/
    schemas/
    repositories/
    services/
    tasks/
    utils/
Backend coding rules

separate API schemas from ORM models

keep business logic in services, not route handlers

keep DB queries out of route files when possible

add timestamps consistently

use migrations for schema changes

do not mix experimental code into production paths

do not expose raw internal tables directly to clients

API rules

use /api/v1/...

use consistent response structure:

success

message

data

error_code

shape APIs around screen needs, not table structure

document request and response examples where possible

State engine rules

When implementing support-state logic:

follow docs/03_지지저항Lab_지지선상태관리_로직명세서.md

do not simplify away key state transitions

keep thresholds configurable where practical

preserve an event history when status changes

Flutter Rules
Flutter priorities

Build only the core MVP screens first:

Home

Watchlist

Stock Search

Stock Detail

Theme

My Page

Notification Settings

Notification List

Flutter architecture guidance

Prefer feature-based structure:

frontend_app/lib/
  core/
  features/
    home/
    watchlist/
    stock/
    theme/
    shorts/
    my/
Flutter coding rules

keep widgets small and composable

create reusable common widgets for:

stock card

status badge

loading state

empty state

error state

prioritize clear user state over visual complexity

keep UI focused on:

current status

price levels

short explanations

do not overbuild the chart area in MVP

Flutter UX rules

home should answer "what should I look at today?"

watchlist is the app core

stock detail is a decision-support screen, not an HTS clone

notifications should deep link to the relevant stock detail or content page

Admin Rules
Admin priorities

The admin must support operator control.

Minimum admin features:

stock CRUD

price level CRUD

support state review

signal event review

home featured stock management

theme management

manual push trigger

audit log viewing

Admin behavior rules

prefer deactivate over hard delete

log all important manual edits

manual overrides must require a memo when practical

operator changes should be traceable

Data Rules
Data handling rules

separate cache data from persistent data

persistent storage should keep history where important

real-time or frequent updates should be cache-friendly

avoid duplicating identical bars for same stock/time

be conservative when data is missing

do not aggressively force status changes on incomplete data

Market data assumptions

This product is not a low-latency trading terminal.
The important output is the interpreted state, not raw ticks.

Testing Rules

For each meaningful implementation phase, add or update tests.

Backend tests

Prefer tests for:

support state transitions

signal event generation

watchlist CRUD

stock search

stock detail API response structure

Flutter tests

At minimum, test:

basic state rendering

empty state rendering

parsing of key API response models

navigation to stock detail where practical

If full test coverage is not realistic for a task, at least test the highest-risk domain logic.

Working Style for Codex

When working on tasks in this repo, follow this behavior:

Before coding

read the relevant docs

identify the exact scope

avoid touching unrelated areas

prefer minimal necessary changes

During coding

do not silently change product scope

do not rename core domain concepts without reason

do not add large dependencies unless necessary

avoid speculative features

After coding

Always provide:

summary of what changed

list of changed files

assumptions made

remaining TODOs

how to run or test the change

Task Execution Policy

For each requested task:

Do

complete the requested phase as fully as possible

keep changes coherent and scoped

leave clear TODOs where work is intentionally incomplete

make the code runnable where practical

Do not

partially rewrite unrelated architecture

introduce unrelated refactors

implement future phases unless necessary

mix MVP and post-MVP features

delete docs

ignore AGENTS.md instructions

Definition of Done

A task is considered done only if:

the requested scope is implemented

changed files are coherent

code is consistent with the docs

obvious syntax/runtime issues are addressed

migrations are included when schema changes occur

summary and assumptions are reported

Preferred First Tasks

When no specific task is given, prefer this order:

Phase 1

backend_api scaffold

DB models

Alembic setup

initial migrations

Phase 2

stock search API

stock detail API

watchlist CRUD API

Phase 3

Flutter home/watchlist/search/detail screens

Phase 4

admin stock/level/state pages

Phase 5

signal events

notifications

push integration

Human Review Notes

This repository is documentation-driven.

When something is unclear:

prefer a minimal implementation aligned with the docs

add a short TODO or assumption note

do not expand scope aggressively

The docs define the product.
The code should follow them.
