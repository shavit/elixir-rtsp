defmodule ExRtsp.RTPGroup do
  @moduledoc """
  Documentation for `ExRtsp.RTPGroup`.
  """
  use GenServer
  alias ExRtsp.RTCP
  alias ExRtsp.RTP
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, rtp_pid} = RTP.start_link(server: self(), port: 3000)
    {:ok, rtcp_pid} = RTCP.start_link(server: self(), port: 3001)

    state = %{
      rtp_pid: rtp_pid,
      rtcp_pid: rtcp_pid
    }

    {:ok, state}
  end

  def handle_call(_msg, _ref, state), do: {:reply, {:error, "not implemented"}, state}
  def handle_cast(_msg, state), do: {:noreply, state}
  def handle_info(_msg, state), do: {:noreply, state}

  def terminate(reason, state) do
    Logger.info("[RTPGroup] Terminated")

    reason
  end
end
