defmodule Yog.MixProject do
  use Mix.Project

  def project do
    [
      app: :yog,
      version: "5.0.0",
      elixir: "~> 1.15",
      compilers: [:gleam] ++ Mix.compilers(),
      deps: [{:mix_gleam, "~> 0.6.2"}]
    ]
  end
end
