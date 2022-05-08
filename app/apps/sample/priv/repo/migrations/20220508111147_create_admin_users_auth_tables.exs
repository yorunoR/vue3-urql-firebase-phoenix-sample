defmodule Sample.Repo.Migrations.CreateAdminUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:admin_users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:admin_users, [:email])

    create table(:admin_users_tokens) do
      add :admin_user_id, references(:admin_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:admin_users_tokens, [:admin_user_id])
    create unique_index(:admin_users_tokens, [:context, :token])
  end
end
