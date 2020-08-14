defmodule ExRtsp.Client do
  @moduledoc """
  Documentation for `ExRtsp.Client`.
  """
  use GenServer
  alias ExRtsp.Request
  alias ExRtsp.Response
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
      port: Keyword.get(opts, :port, 1935),
      protocol: Keyword.get(opts, :protocol, :tcp),
      session_id: <<>>
    }

    {:ok, state, {:continue, :dial_rtsp}}
  end

  def handle_continue(:dial_rtsp, state) do
    {:ok, sock} = reconnect(state.host, state.port)

    req =
      [
        url: "rtmp://192.168.2.7:554/s0",
        cseq: state.cseq,
        method: :describe
      ]
      |> Request.new()

    send_req(sock, req)

    # req =
    #   Request.new(url: "rtmp://192.168.2.7:554/s0/trackID=1", cseq: state.cseq + 1, method: :setup, transport: Request.option_set_transport_default())
    # send_req(sock, req)

    {:noreply, %{state | conn: sock}}
  end

  def reconnect(host, port) do
    opts = [:binary, {:packet, 0}, {:active, true}]
    :gen_tcp.connect(host, port, opts)
  end

  def send_req(sock, %Request{} = req) do
    req = Request.encode(req)
    Logger.debug("Send request")
    :gen_tcp.send(sock, req)
  end

  def handle_call({:send_req, req}, _ref, state) do
    state = %{state | cseq: state.cseq + 1}

    req =
      req
      |> Map.put(:cseq, state.cseq)
      |> Map.put(:session_id, state.session_id)

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("TCP message: #{msg}")

    case Response.new(msg) do
      %Response{session: session} ->
        {:noreply, %{state | session_id: session}}

      {:error, reason} ->
        Logger.error("Error: #{reason}: #{inspect(msg)}")
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("TCP closed")

    {:noreply, Map.delete(state, :conn)}
  end
end
