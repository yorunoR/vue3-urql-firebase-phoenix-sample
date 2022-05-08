defmodule Sample.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :uid, :string
      add :email, :string
      add :role, :integer
      add :activated, :boolean, default: false, null: false
      add :profile_image, :string

      timestamps()
      soft_delete_columns()
    end
  end
end
