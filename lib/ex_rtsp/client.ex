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

    state = %{
      abs_path: Keyword.get(opts, :abs_path, "/s0"),
      conn: nil,
      content_base: "/",
      cseq: 0,
      host: Keyword.get(opts, :host, "127.0.0.1"),
      port: opts |> Keyword.get(:port, 554) |> to_string() |> String.to_integer(),
      protocol: Keyword.get(opts, :protocol, :tcp),
      channels: [],
      session_id: <<>>,
      media: %{}
    }

    {:ok, state, {:continue, :dial_rtsp}}
  end

  def handle_continue(:dial_rtsp, state) do
    {:ok, sock} = state.host |> String.to_charlist() |> reconnect(state.port)
    state = %{state | conn: sock}

    {res, state} =
      [
        url: build_url(state),
        cseq: state.cseq,
        method: :describe
      ]
      |> Request.new()
      |> send_req(state)

    {:noreply, %{state | conn: sock}}
  end

  defp build_url(state), do: "rtsp://#{state.host}:#{state.port}#{state.abs_path}"

  defp reconnect(host, port) do
    opts = [:binary, {:packet, 0}, {:active, true}]
    :gen_tcp.connect(host, port, opts)
  end

  defp connect_to_media({medium, props}) do
    props |> Map.put(:medium, medium)
  end

  defp handle_describe(%Response{} = resp, state) do
    media =
      resp
      |> Map.get(:media, %{})
      |> Map.take(["audio", "video"])
      |> Enum.map(&connect_to_media/1)

    # medium = List.first(media)
    medium = media |> Enum.filter(&(&1.medium == "video")) |> List.first()
    {:ok, _rtp_pid} = RTP.start_link(server: self(), port: 3000, medium: medium)
    {:ok, _rtcp_pid} = RTCP.start_link(server: self(), port: 3001, medium: medium)

    %{
      state
      | session_id: resp.session,
        content_base: resp.content_base,
        media: media
    }
  end

  defp send_req(_req, %{conn: nil} = state), do: {{:error, "need to reconnect"}, state}

  defp send_req(%Request{} = req, state) do
    req = Request.encode(req)
    Logger.debug(fn -> "Send request #{state.cseq}" end)

    res = :gen_tcp.send(state.conn, req)
    {res, %{state | cseq: state.cseq + 1}}
  end

  def handle_call({:describe, _opts}, _ref, state) do
    {res, state} =
      Request.new(
        url: build_url(state),
        cseq: state.cseq + 1,
        method: :describe
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:setup, opts}, _ref, state) do
    transport = Keyword.get(opts, :transport, Request.option_set_transport_default())
    track_id = state.media |> List.last() |> Map.get(:track_id)
    url = state.content_base <> "trackID=#{track_id}"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :setup,
        transport: transport,
        accept: Keyword.get(opts, :accept, "application/sdp")
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:play, opts}, _ref, state) do
    track_id = state.media |> List.last() |> Map.get(:track_id)
    url = state.content_base <> "trackID=#{track_id}"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :play,
        session: state.session_id,
        range: Keyword.get(opts, :range, {10})
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:pause, _opts}, _ref, state) do
    track_id = state.media |> List.last() |> Map.get(:track_id)
    url = state.content_base <> "trackID=#{track_id}"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :pause,
        session: state.session_id
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:record, _opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        content_base: state.content_base,
        method: :record,
        session: state.session_id
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:teardown, _opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :record,
        session: state.session_id
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:set_parameter, opts}, _ref, state) do
    url = build_url(state) <> "/trackID=1"

    {res, state} =
      Request.new(
        url: url,
        cseq: state.cseq + 1,
        method: :record,
        session: state.session_id,
        parameter: Keyword.get(opts, :parameter)
      )
      |> send_req(state)

    {:reply, res, state}
  end

  def handle_call({:send_req, req}, _ref, state) do
    state = %{state | cseq: state.cseq + 1}

    {res, state} =
      req
      |> Map.put(:cseq, state.cseq)
      |> Map.put(:session_id, state.session_id)

    {res, state} = send_req(req, state)

    {:reply, res, state}
  end

  def handle_cast({:send_seq, req}, state) do
    state = %{state | cseq: state.cseq + 1}
    Logger.info("Send request #{inspect(req)}")

    {:noreply, state}
  end

  def handle_info({:tcp, _from, msg}, state) do
    Logger.info("TCP message: #{msg}")

    case Response.new(msg) do
      %Response{status: 404, content_base: base} ->
        Logger.error("Error: Route not found /#{base}")
        {:noreply, state}

      %Response{session: session, content_base: nil} = resp ->
        {:noreply, %{state | session_id: session}}

      %Response{media: _media} = resp ->
        {:noreply, handle_describe(resp, state)}

      {:error, reason} ->
        Logger.error("Error: #{reason}: #{inspect(msg)}")
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info("TCP closed")

    {:noreply, %{state | conn: nil}}
  end
end
