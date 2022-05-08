defmodule Graphql.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  object :user do
    field(:id, :id)
    field(:activated, :boolean)
    field(:email, :string)
    field(:name, :string)
    field(:profile_image, :string)
    field(:role, :integer)
    field(:uid, :string)
  end
end
