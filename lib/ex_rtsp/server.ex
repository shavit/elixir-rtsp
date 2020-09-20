defmodule ExRtsp.Server do
  @moduledoc """
  Documentation for `ExRtsp.Server`.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    port = opts |> Keyword.get(:port, "8554") |> String.to_integer()
    {:ok, socket} = :gen_tcp.listen(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket
    }

    {:ok, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("New message: #{inspect(msg)}")
    {:noreply, state}
  end
end
