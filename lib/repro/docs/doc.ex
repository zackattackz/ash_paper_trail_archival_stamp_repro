defmodule Repro.Docs.Doc do
  use Ash.Resource,
    domain: Repro.Docs,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource, AshArchival.Resource]

  postgres do
    table "docs"
    repo Repro.Repo
  end

  temporal do
    strategy :context
    attribute :valid_at
  end

  paper_trail do
    mode :temporal_inline
    version_resource? true
    change_tracking_mode :previous_values
    store_action_name? true
    on_actions [:create, :update, :destroy, :archive]
    belongs_to_actor :user, Repro.Docs.User, domain: Repro.Docs
  end

  archive do
    exclude_read_actions [:including_archived]
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy, create: [:title], update: [:title]]
    read :including_archived

    # The same archive as AshArchival's destroy, written as an update.
    update :archive do
      accept []
      change set_attribute(:archived_at, &DateTime.utc_now/0)
    end
  end
end
