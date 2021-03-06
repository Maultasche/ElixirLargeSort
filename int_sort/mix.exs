defmodule IntSort.MixProject do
  use Mix.Project

  def project do
    [
      app: :int_sort,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript_config(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:largesort_shared, path: "../largesort_shared"},
      {:progress_bar, "~> 2.0"},
      {:mox, "~> 0.5.1", only: [:test]},
      {:poison, "~> 4.0", only: [:test]},
      # {:math, "~> 0.3.0", only: [:test]},
      {:int_gen, path: "../int_gen", only: [:test]}
    ]
  end

  defp escript_config do
    [
      main_module: IntSort.CLI
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
