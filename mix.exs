defmodule ExRtsp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_rtsp,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExRtsp",
      description: "RTSP library",
      docs: [
        main: "ExRtsp",
        extras: ["README.md"]
      ],
      package: [
        links: %{
          "Github" => "https://github.com/shavit/elixir-rtsp"
        },
        licenses: ["Apache 2.0"]
      ],
      source_url: "https://github.com/shavit/elixir-rtsp"
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
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
