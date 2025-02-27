import Config

config :quadblockquiz, Quadblockquiz.Repo,
  username: "postgres",
  password: "postgres",
  database: "quadblockquiz_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :quadblockquiz, QuadblockquizWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "build.js",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ],
    npx: [
      "tailwindcss",
      "--input=css/app_tailwind.css",
      "--output=../priv/static/assets/app_tailwind.css",
      "--postcss",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :quadblockquiz,
  base_questions_directory: Path.dirname(__DIR__)

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :quadblockquiz, QuadblockquizWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/quadblockquiz_web/(live|views)/.*(ex)$",
      ~r"lib/quadblockquiz_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
