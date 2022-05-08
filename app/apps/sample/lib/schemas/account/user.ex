defmodule Schemas.Account.User do
  use Ecto.Schema
  import Ecto.SoftDelete.Schema

  schema "users" do
    field :activated, :boolean, default: false
    field :email, :string
    field :name, :string
    field :profile_image, :string
    field :role, :integer
    field :uid, :string

    timestamps()
    soft_delete_schema()
  end
end
