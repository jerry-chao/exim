defmodule Exim.Repo.Migrations.AddChannelFeatures do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :is_public, :boolean, default: true, null: false
      add :creator_id, references(:users, on_delete: :nilify_all)
      add :member_count, :integer, default: 0, null: false
    end

    create index(:channels, [:is_public])
    create index(:channels, [:creator_id])
  end
end
