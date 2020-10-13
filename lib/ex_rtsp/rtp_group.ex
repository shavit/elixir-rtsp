defmodule ExRtsp.RTPGroup do
  @moduledoc """
  Documentation for `ExRtsp.RTPGroup`.
  """
  use GenServer
  alias ExRtsp.RTCP
  alias ExRtsp.RTP

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, rtp_pid} = RTP.start_link(server: self())
    {:ok, rtcp_pid} = RTCP.start_link(server: self())

    state = %{
      rtp_pid: rtp_pid,
      rtcp_pid: rtcp_pid
    }

    {:ok, state}
  end
end
