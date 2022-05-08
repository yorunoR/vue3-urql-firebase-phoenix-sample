defmodule Graphql.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.CommonTypes)

  query do
    field :ping, :status do
      resolve(fn _, _, _ -> {:ok, %{status: true}} end)
    end
  end

  # mutation do
  # end

  # subscription do
  # end
end
