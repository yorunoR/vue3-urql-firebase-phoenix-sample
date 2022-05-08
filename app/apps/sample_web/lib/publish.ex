defmodule Publish do
  alias Absinthe.Subscription
  alias SampleWeb.Endpoint

  def new_user(user) do
    Subscription.publish(Endpoint, user, new_user: "*")
  end
end
