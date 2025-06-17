defmodule Exim.Repo.Migrations.CreateChannelsAndUserChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string, null: false
      add :description, :text
      timestamps()
    end

    create unique_index(:channels, [:name])

    create table(:user_channels) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :channel_id, references(:channels, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:user_channels, [:user_id])
    create index(:user_channels, [:channel_id])
    create unique_index(:user_channels, [:user_id, :channel_id])

    # Add channel_id to messages table
    alter table(:messages) do
      add :channel_id, references(:channels, on_delete: :delete_all)
    end

    create index(:messages, [:channel_id])
  end
end
