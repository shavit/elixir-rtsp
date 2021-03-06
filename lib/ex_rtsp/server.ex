defmodule ExRtsp.Server do
  @moduledoc """
  Documentation for `ExRtsp.Server`.
  """
  use GenServer
  require Logger
  alias ExRtsp.SDP.Request
  alias ExRtsp.SDP.Response

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    port = opts |> Keyword.get(:port, 8554) |> to_string() |> String.to_integer()
    {:ok, lsock} = :gen_tcp.listen(port, [:binary, {:active, true}])

    state = %{
      cseq: 0,
      port: port,
      lsock: lsock,
      sock: nil,
      host: Keyword.get(opts, :host, get_default_host()),
      config: Keyword.get(opts, :config, %{})
    }

    {:ok, state, {:continue, :accept_connections}}
  end

  def handle_continue(:accept_connections, state) do
    {:ok, sock} = :gen_tcp.accept(state.lsock)

    {:noreply, %{state | sock: sock}}
  end

  def handle_info({:tcp, from, msg}, state) do
    Logger.info("New message: #{inspect(msg)}")
    state = msg |> Request.decode() |> handle_request(from, state)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("Connection closed by client")
    {:noreply, state}
  end

  defp get_default_host do
    case :inet.getif() do
      {:ok, l} when is_list(l) -> l |> Enum.at(1) |> elem(1) |> Tuple.to_list() |> Enum.join(".")
      _ -> "127.0.0.1"
    end
  end

  defp handle_request(%Request{method: "DESCRIBE"}, from, state) do
    if !is_nil(from), do: :gen_tcp.send(from, Response.describe())

    state
  end

  defp handle_request(%Request{} = req, _from, state) do
    Logger.info("handle_request/2 #{inspect(req)}")

    state
  end
end
