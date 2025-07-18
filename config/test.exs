import Config

# Definition environment
config :policr_mini, :environment, :test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :policr_mini, PolicrMini.Repo,
  username: "postgres",
  password: "postgres",
  database: "policr_mini_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  migration_timestamps: [type: :utc_datetime]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :policr_mini, PolicrMiniWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
