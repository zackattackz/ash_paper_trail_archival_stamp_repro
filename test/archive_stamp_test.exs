defmodule Repro.ArchiveStampTest do
  @moduledoc """
  A temporal resource with AshPaperTrail `mode :temporal_inline` and
  AshArchival. Sam creates a doc at 09:00, Dana archives it at 10:00. The
  archive writes a new period row from 10:00 with `archived_at` set, and that
  row should carry Dana's stamp.

  Every write passes an explicit `as_of`, so the test doesn't depend on the
  clock.
  """
  use ExUnit.Case, async: false

  require Ash.Query

  alias Repro.Docs.{Doc, User}

  @created_at ~U[2026-01-01 09:00:00.000000Z]
  @archived_at ~U[2026-01-01 10:00:00.000000Z]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repro.Repo)
    sam = Ash.create!(User, %{name: "Sam"})
    dana = Ash.create!(User, %{name: "Dana"})

    doc =
      Doc
      |> Ash.Changeset.for_create(:create, %{title: "A"}, actor: sam, as_of: @created_at)
      |> Ash.create!()

    %{sam: sam, dana: dana, doc: doc}
  end

  defp versions(id) do
    Doc.Version
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.sort(valid_at: :asc)
    |> Ash.read!()
    |> Enum.map(fn version ->
      version
      |> Map.take([:title, :archived_at, :user_id, :version_action_type, :version_action_name, :changes])
      |> Map.put(:from, version.valid_at.lower)
    end)
  end

  test "archiving with Ash.destroy/2 stamps the archive with its actor", %{sam: sam, dana: dana, doc: doc} do
    Ash.destroy!(doc, actor: dana, as_of: @archived_at)

    assert [created, archived] = versions(doc.id)
    IO.inspect([created, archived], label: "\nversions after Ash.destroy!(doc, actor: dana)")

    assert created.from == @created_at
    assert created.user_id == sam.id
    assert archived.from == @archived_at
    assert archived.archived_at == @archived_at
    assert archived.user_id == dana.id
    assert archived.version_action_name == :destroy
  end

  test "works: the same archive as an update action", %{sam: sam, dana: dana, doc: doc} do
    doc
    |> Ash.Changeset.for_update(:archive, %{}, actor: dana, as_of: @archived_at)
    |> Ash.update!()

    assert [created, archived] = versions(doc.id)
    assert created.user_id == sam.id
    assert archived.from == @archived_at
    assert archived.archived_at == @archived_at
    assert archived.user_id == dana.id
    assert archived.version_action_name == :archive
    assert archived.changes == %{"archived_at" => nil}
  end
end
