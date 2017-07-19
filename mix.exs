defmodule Soapex.Mixfile do
  use Mix.Project

  def project do
    [app: :soapex,
     version: "0.1.0",
     elixir: "~> 1.2",
     deps: deps(),
     description: "Erlsom/Detergent wrapper for Elixir/Phoenix",
     package: package()]
  end

  def application do
    [applications: [:plug, :erlsom, :detergent]]
  end

  defp deps do
    [{:plug, "~> 1.0"},
     # mostly merged already
     {:erlsom,    github: "frobese/erlsom",    branch: "develop"},
     # this is detergent 0.3.0 extended to support ssl client certs
     {:detergent, github: "active-group/detergent", tag: "eco-v3"}]
  end

  defp package do
    [maintainers: ["Christian Zuckschwerdt"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/active-group/soapex"},
     files: ~w(lib LICENSE mix.exs README.md)]
  end
end
