defmodule Graphql.Schema.CommonTypes do
  use Absinthe.Schema.Notation

  object :item do
    field(:key, :string)
    field(:val, :string)
  end

  object :status do
    field(:status, :boolean)
  end
end
