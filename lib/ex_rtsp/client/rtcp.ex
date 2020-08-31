defmodule ExRtsp.Client.RTCP do
  @moduledoc """
  Documentation for `ExRtsp.Client.RTCP`.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    port = Keyword.get(opts, :port, 3001)
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket
    }

    {:ok, state}
  end

  def handle_call(:stop, _ref, state) do
    Logger.info("[Client.RTCP] stop")

    {:reply, state, state}
  end

  def handle_info({:udp, _port, _ip, _udp_port, msg}, state) do
    Logger.info("[Client.RTCP] New message: #{inspect(msg)}")
    Logger.info("[Client.RTCP] #{inspect(decode(msg))}")

    {:noreply, state}
  end

  defp decode(<<v::2, p::1, rc::5, pt::8, l::16, ssrc::32, _body::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: pt,
      length: l,
      ssrc: ssrc
    }
  end

  defp encode(_), do: nil
end
