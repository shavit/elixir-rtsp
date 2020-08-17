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
      abs_path: Keyword.get(opts, :abs_path, "/s0"),
      conn: nil,
      cseq: 0,
      host: Keyword.get(opts, :host, "127.0.0.1"),
      port: Keyword.get(opts, :port, 554),
      protocol: Keyword.get(opts, :protocol, :tcp),
      session_id: <<>>
    }

    {:ok, state, {:continue, :dial_rtsp}}
  end

  def handle_continue(:dial_rtsp, state) do
    {:ok, sock} = state.host |> String.to_charlist() |> reconnect(state.port)

    req =
      [
        url: build_url(state),
        cseq: state.cseq,
        method: :describe
      ]
      |> Request.new()

    send_req(sock, req)

    {:noreply, %{state | conn: sock}}
  end

  defp build_url(state), do: "rtmp://#{state.host}:#{state.port}#{state.abs_path}"

  def reconnect(host, port) do
    opts = [:binary, {:packet, 0}, {:active, true}]
    :gen_tcp.connect(host, port, opts)
  end

  def send_req(sock, %Request{} = req) do
    req = Request.encode(req)
    Logger.debug("Send request")
    :gen_tcp.send(sock, req)
  end

  def handle_call({:setup, opts}, _ref, state) do
    transport = Keyword.get(opts, :transport, Request.option_set_transport_default())
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :setup,
        transport: transport
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:play, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :play,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:pause, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :pause,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:record, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :record,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:teardown, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :record,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
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
