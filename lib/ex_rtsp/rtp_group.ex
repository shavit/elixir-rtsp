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
    children = [
      {RTP, [opts]},
      {RTCP, [opts]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
