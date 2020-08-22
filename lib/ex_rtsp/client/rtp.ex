defmodule ExRtsp.Client.RTP do
  @moduledoc """
  Documentation for `ExRtsp.Client.RTP`.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    port = Keyword.get(opts, :port, 3000)
    {:ok, socket} = :gen_tcp.listen(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket
    }

    {:ok, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("[Client.RTP] New message: #{inspect(msg)}")
    {:noreply, state}
  end
end
