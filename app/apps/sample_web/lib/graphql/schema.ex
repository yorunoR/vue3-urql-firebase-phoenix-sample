defmodule Graphql.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.CommonTypes)
  import_types(__MODULE__.AccountTypes)

  query do
    field :ping, :status do
      resolve(fn _, _, _ -> {:ok, %{status: true}} end)
    end
  end

  # mutation do
  # end

  subscription do
    field :new_user, :user do
      config(fn _args, _ ->
        {:ok, topic: "*"}
      end)
    end
  end
end
