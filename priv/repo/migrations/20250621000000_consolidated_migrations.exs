defmodule Exim.Repo.Migrations.ConsolidatedMigrations do
  use Ecto.Migration

  def change do
    # Create channels table
    create table(:channels) do
      add :name, :string, null: false
      add :description, :text
      add :is_public, :boolean, default: true, null: false
      add :creator_id, references(:users, on_delete: :nilify_all)
      add :member_count, :integer, default: 0, null: false
      timestamps()
    end

    create unique_index(:channels, [:name])
    create index(:channels, [:is_public])
    create index(:channels, [:creator_id])

    # Create user_channels junction table
    create table(:user_channels) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :channel_id, references(:channels, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:user_channels, [:user_id])
    create index(:user_channels, [:channel_id])
    create unique_index(:user_channels, [:user_id, :channel_id])

    # Create messages table
    create table(:messages) do
      add :content, :text
      add :from_id, references(:users, on_delete: :nothing)
      add :channel_id, references(:channels, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:from_id])
    create index(:messages, [:channel_id])
  end
end
