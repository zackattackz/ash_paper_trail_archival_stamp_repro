defmodule Repro.Docs.User do
  use Ash.Resource,
    domain: Repro.Docs,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo Repro.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, create: [:name]]
  end
end
