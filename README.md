# AshPaperTrail `:temporal_inline`: an AshArchival archive keeps the previous version's stamp

Minimal reproduction for an AshPaperTrail bug. On a temporal resource with
`mode :temporal_inline` and AshArchival, archiving with `Ash.destroy/2` writes
a new period row with `archived_at` set. That row carries the *previous*
version's stamp (its user, action and changes), not the archive's. The guide
says this setup is how to record who destroyed a record.

- ash 3.36.1, ash_postgres 2.14.5, ash_paper_trail 0.8.0, ash_archival 2.0.4,
  PostgreSQL 18
- Elixir 1.20.4, Erlang/OTP 29 (`.tool-versions`)
- One temporal resource, `Repro.Docs.Doc`, and a plain `Repro.Docs.User` as
  the actor.
- AshArchival's two modules are listed in `config :ash, :temporal_safe_modules`
  (`config/config.exs`). They don't declare `temporal_safe?/1` yet, and a
  temporal resource can't use them otherwise.

## Run

It needs PostgreSQL 18. The default `DATABASE_URL` points at port **54321**,
not 5432, so it doesn't use a Postgres you already run. A throwaway server:

```sh
docker run --rm -p 54321:5432 -e POSTGRES_PASSWORD=postgres postgres:18
```

Then:

```sh
mix deps.get
mix test
```

To use another server, set `DATABASE_URL`, for example
`postgres://user:pass@localhost:5432/ash_paper_trail_archival_repro`.

### What it does to the database

`mix test` runs `mix ash.setup` first, which creates and migrates. It never
drops anything. On the server `DATABASE_URL` names, it:

- creates the database `ash_paper_trail_archival_repro` if it doesn't exist;
- installs `btree_gist` and Ash's `ash_*` SQL functions in that database
  only;
- creates `users` and `docs` tables.

Each test runs in a transaction that is rolled back, so no rows are left. No
other database is read or changed. To remove what it created:

```sh
mix ecto.drop   # or stop the docker container above (--rm discards it)
```

In `test/archive_stamp_test.exs`, Sam creates a doc as of 09:00. Dana then
archives it as of 10:00 with `Ash.destroy!(doc, actor: dana, as_of: ...)`.
Every write passes an explicit `as_of`, so nothing depends on the clock. The
archive row from 10:00 should be stamped with Dana and `:destroy`. It is
stamped with Sam and `:create`, copied from the row before it:

```
versions after Ash.destroy!(doc, actor: dana): [
  %{title: "A", from: ~U[2026-01-01 09:00:00.000000Z], archived_at: nil,
    user_id: "<sam>", version_action_type: :create, version_action_name: :create, changes: %{}},
  %{title: "A", from: ~U[2026-01-01 10:00:00.000000Z], archived_at: ~U[2026-01-01 10:00:00.000000Z],
    user_id: "<sam>", version_action_type: :create, version_action_name: :create, changes: %{}}
]

Assertion with == failed
code:  assert Map.take(archived, [:user_id, :version_action_name]) ==
         %{user_id: dana.id, version_action_name: :destroy}
left:  %{user_id: "<sam>", version_action_name: :create}
right: %{user_id: "<dana>", version_action_name: :destroy}
```

The second test archives with an ordinary update action that sets
`archived_at`, and passes: that row is stamped with Dana, `:archive` and
`changes: %{"archived_at" => nil}`.
