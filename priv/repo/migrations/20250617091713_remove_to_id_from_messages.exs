defmodule Exim.Repo.Migrations.RemoveToIdFromMessages do
  use Ecto.Migration

  def change do
    drop index(:messages, [:to_id])

    alter table(:messages) do
      remove :to_id
    end
  end
end
