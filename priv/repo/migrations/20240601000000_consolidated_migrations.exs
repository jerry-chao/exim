defmodule Exim.Repo.Migrations.ConsolidatedMigrations do
  use Ecto.Migration

  def change do
    # Create users table
    create table(:users) do
      add :email, :string
      add :password_hash, :string
      add :username, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])

    # Create users_tokens table
    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # Create messages table
    create table(:messages) do
      add :content, :text
      add :from_id, references(:users, on_delete: :nothing)
      add :to_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:from_id])
    create index(:messages, [:to_id])
  end
end
