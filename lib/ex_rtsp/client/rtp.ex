defmodule ExRtsp.Client.RTP do
  @moduledoc """
  Documentation for `ExRtsp.Client.RTP`.
  """
  use GenServer
  require Logger
  alias ExRtsp.Encoder.Ffmpeg

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    {:ok, encoder_socket} = Ffmpeg.setup(opts)
    port = Keyword.get(opts, :port, 3000)
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket,
      encoder_socket: encoder_socket
    }

    {:ok, state}
  end

  def handle_call(:stop, _ref, state) do
    Logger.info("[Client.RTCP] stop")

    {:reply, state, state}
  end

  def handle_info({:udp, _port, _ip, _udp_port, msg}, state) do
    Ffmpeg.encode(state.encoder_socket, msg)

    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.info("[Client.RTP] Terminated")
    Ffmpeg.teardown(state.encoder_socket)

    reason
  end
end
