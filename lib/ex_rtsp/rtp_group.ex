defmodule ExRtsp.RTPGroup do
  @moduledoc """
  Documentation for `ExRtsp.RTPGroup`.
  """
  use Supervisor
  alias ExRtsp.RTCP
  alias ExRtsp.RTP
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    rtp_port = Keyword.get(opts, :port, 3000)
    rtcp_port = rtp_port + 1

    children = [
      {RTP, [Keyword.put(opts, :port, rtp_port)]},
      {RTCP, [Keyword.put(opts, :port, rtcp_port)]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def children_for_media(_media, opts) do
    [
      {RTP, [Keyword.put(opts, :port, 3000)]},
      {RTCP, [Keyword.put(opts, :port, 3001)]}
    ]
  end

  def children_for_media(:video, opts) do
    port = Keyword.get(opts, :port)
    [
      {RTP, [Keyword.put(opts, :port, port)]},
      {RTCP, [Keyword.put(opts, :port, port + 1)]}
    ]
  end

  def handle_call(:ping, _ref, state), do: {:reply, :pong, state}
end
