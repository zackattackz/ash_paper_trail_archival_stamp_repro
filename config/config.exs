import Config

config :repro, ash_domains: [Repro.Docs], ecto_repos: [Repro.Repo]

# Any PostgreSQL 18 server, for example:
#   docker run --rm -p 54321:5432 -e POSTGRES_PASSWORD=postgres postgres:18
config :repro, Repro.Repo,
  url:
    System.get_env(
      "DATABASE_URL",
      "postgres://postgres:postgres@localhost:54321/ash_paper_trail_archival_repro"
    ),
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning

# Required by Ash 3.36.
config :ash, default_string_length_count: :codepoints

# AshArchival's modules don't declare `temporal_safe?/1` yet. Their source is
# safe (a filter, and destroys of related records through Ash), so they are
# listed here to let a temporal resource use AshArchival at all.
config :ash, :temporal_safe_modules, [
  AshArchival.Resource.Preparations.FilterArchived,
  AshArchival.Resource.Changes.ArchiveRelated
]
