defmodule ExRtsp.Server do
  @moduledoc """
  Documentation for `ExRtsp.Server`.
  """
  use GenServer
  require Logger
  alias ExRtsp.Response

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    port = opts |> Keyword.get(:port, 8554) |> to_string() |> String.to_integer()
    {:ok, lsock} = :gen_tcp.listen(port, [:binary, {:active, true}])

    state = %{
      port: port,
      lsock: lsock,
      sock: nil
    }

    {:ok, state, {:continue, :accept_connections}}
  end

  def handle_continue(:accept_connections, state) do
    {:ok, sock} = :gen_tcp.accept(state.lsock)

    {:noreply, %{state | sock: sock}}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("New message: #{inspect(msg)}")
    Logger.info(inspect(Response.new(msg)))
    state = handle_request(msg, state)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("Connection closed by client")
    {:noreply, state}
  end

  defp handle_request(msg, state) do
    Logger.info("handle_request/2 #{inspect(msg)}")
    msg

    state
  end
end
