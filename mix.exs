defmodule SingulaQueue.MixProject do
  use Mix.Project

  def project do
    [
      app: :singula_queue,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: ["test.watch": :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_aws_sqs, "~> 3.0"},
      {:saxy, "~> 1.1"},
      {:httpoison, "~> 1.7"},
      {:mix_test_watch, "~> 1.0", only: :test},
      {:hammox, "~> 0.2", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
