defmodule ExRtsp.Client do
  @moduledoc """
  Documentation for `ExRtsp.Client`.
  """
  use GenServer
  alias ExRtsp.Request
  alias ExRtsp.Response
  alias ExRtsp.RTCP
  alias ExRtsp.RTP
  require Logger

  @api_calls [
    :describe,
    :setup,
    :play,
    :pause,
    :record,
    :announce,
    :teardown,
    :set_parameter
  ]
  for api_call <- @api_calls do
    @doc """
    unquote(api_call)/2 makes unquote(api_call) API call
    """
    def unquote(api_call)(pid, opts \\ []) do
      GenServer.call(pid, {unquote(api_call), opts})
    end
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, :exrtsp_client)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    if is_nil(Keyword.get(opts, :host)),
      do: Logger.warn("Missing client host, using localhost instead")

    {:ok, rtp_pid} = RTP.start_link([])
    {:ok, rtcp_pid} = RTCP.start_link([])

    state = %{
      abs_path: Keyword.get(opts, :abs_path, "/s0"),
      conn: nil,
      content_base: "/",
      cseq: 0,
      host: Keyword.get(opts, :host, "127.0.0.1"),
      port: opts |> Keyword.get(:port, 554) |> to_string() |> String.to_integer(),
      protocol: Keyword.get(opts, :protocol, :tcp),
      rtcp_pid: rtcp_pid,
      rtp_pid: rtp_pid,
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

  defp build_url(state), do: "rtsp://#{state.host}:#{state.port}#{state.abs_path}"

  defp reconnect(host, port) do
    opts = [:binary, {:packet, 0}, {:active, true}]
    :gen_tcp.connect(host, port, opts)
  end

  defp send_req(sock, %Request{} = req) do
    req = Request.encode(req)
    Logger.debug("Send request")
    :gen_tcp.send(sock, req)
  end

  def handle_call({:describe, opts}, _ref, state) do
    req =
      Request.new(
        url: build_url(state),
        cseq: state.cseq + 1,
        method: :describe
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:setup, opts}, _ref, state) do
    transport = Keyword.get(opts, :transport, Request.option_set_transport_default())
    url = state.content_base <> "trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :setup,
        transport: transport,
        accept: Keyword.get(opts, :accept, "application/sdp")
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:play, opts}, _ref, state) do
    url = state.content_base <> "trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :play,
        session: state.session_id,
        range: Keyword.get(opts, :range, {10})
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:pause, _opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :pause,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:record, _opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :record,
        session: state.session_id
      )

    res = send_req(state.conn, req)

    {:reply, res, state}
  end

  def handle_call({:teardown, _opts}, _ref, state) do
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

  def handle_call({:set_parameter, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    req =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :record,
        session: state.session_id,
        parameter: Keyword.get(opts, :parameter)
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

  def handle_call(%{protocol: :tcp, rtcp_pid: rtcp, rtp_pid: rtp}, _ref, state) do
    GenServer.call(rtcp, :stop)
    GenServer.call(rtp, :stop)

    {:reply, state, state}
  end

  def handle_call(_msg, _ref, state) do
    GenServer.call(state.rtcp_pid, :stop)
    GenServer.call(state.rtp_pid, :stop)

    {:reply, nil, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("TCP message: #{msg}")

    case Response.new(msg) do
      %Response{status: 404, content_base: base} ->
        Logger.error("Error: Route not found /#{base}")
        {:noreply, state}

      %Response{session: session, content_base: nil} ->
        {:noreply, %{state | session_id: session}}

      %Response{session: session, content_base: content_base} ->
        {:noreply, %{state | session_id: session, content_base: content_base}}

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
