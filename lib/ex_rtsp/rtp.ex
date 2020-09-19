defmodule ExRtsp.RTP do
  @moduledoc """
  Documentation for `ExRtsp.RTP`.
  """
  use GenServer
  require Logger
  alias ExRtsp.Encoder.Ffmpeg
  alias ExRtsp.Encoder.Video

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    {:ok, encoder_socket, tmp_file} = Ffmpeg.setup(opts)
    port = Keyword.get(opts, :port, 3000)
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket,
      encoder_socket: encoder_socket,
      tmp_file: tmp_file,
      job_id: Keyword.get(opts, :job_id)
    }

    {:ok, state}
  end

  def handle_call(:stop, _ref, state) do
    Logger.info("[Client.RTP] stop")

    {:reply, state, state}
  end

  def handle_info({:udp, _port, _ip, _udp_port, msg}, state) do
    msg_decoded = decode(msg)
    body = msg_decoded.payload
    Ffmpeg.encode(state.tmp_file, body)

    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.info("[Client.RTP] Terminated")
    Ffmpeg.teardown(state.encoder_socket, state.job_id)

    reason
  end

  def decode(<<v::2, p::1, x::1, cc::4, m::1, pt::7, seq::16, tm::32, ssrc::32, b::binary>>) do
    %{
      version: v,
      padding: p == 1,
      extension: x == 1,
      csrc_count: cc,
      marker: m,
      payload_type: pt,
      sequence: seq,
      timestamp: tm,
      ssrc_identifier: ssrc,
      payload: b
    }
  end
end