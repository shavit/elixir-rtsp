defmodule ExRtsp.Client do
  @moduledoc """
  Documentation for `ExRtsp.Client`.
  """
  use GenServer
  alias ExRtsp.Request
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, :exrtsp_client)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    if is_nil(Keyword.get(opts, :host)),
      do: Logger.warn("Missing client host, using localhost instead")

    state = %{
      conn: nil,
      cseq: 0,
      host: opts |> Keyword.get(:host, "127.0.0.1") |> String.to_charlist(),
      port: Keyword.get(opts, :port, 1935)
    }

    {:ok, state, {:continue, :dial_rtsp}}
  end

  def handle_continue(:dial_rtsp, state) do
    {:ok, sock} = reconnect(state.host, state.port)

    req =
      [
        url: "rtmp://192.168.2.7:554",
        cseq: state.cseq,
        method: :options
      ]
      |> Request.new()

    send_req(sock, req)

    {:noreply, %{state | conn: sock}}
  end

  def reconnect(host, port) do
    opts = [:binary, {:packet, 0}, {:active, true}]
    :gen_tcp.connect(host, port, opts)
  end

  def send_req(sock, %Request{} = req) do
    req = Request.encode(req)
    :gen_tcp.send(sock, req)
  end

  def handle_call({:send_req, req}, _ref, state) do
    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("TCP message: #{msg}")

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("TCP closed")

    {:noreply, Map.delete(state, :conn)}
  end
end
