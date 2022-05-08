defmodule Sample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Sample.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sample.PubSub}
      # Start a worker by calling: Sample.Worker.start_link(arg)
      # {Sample.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Sample.Supervisor)
  end
end
