defmodule IntGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :int_gen,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
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
      {:mox, "~> 0.5.1", only: [:test]}
    ]
  end
end
