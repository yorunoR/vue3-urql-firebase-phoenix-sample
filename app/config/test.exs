import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sample, Sample.Repo,
  username: "developer",
  password: "secret",
  hostname: System.get_env("DOCKER_POSTGRES_HOST") || "localhost",
  database: "sample_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sample_web, SampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "zyuC9eYkv6BLFvGsNhpRyW3Imq1CbSt99rX2YAFc8xUkb9RA/z/ZAWm6XfpInRR0",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :sample, Sample.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
