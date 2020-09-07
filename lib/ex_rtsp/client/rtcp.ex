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

  def decode(<<v::2, p::1, rc::5, pt::8, l::16, ssrc::32, rp::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: pt,
      length: l,
      ssrc: ssrc,
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  defp decode_report_blocks(<<>>, []), do: []
  defp decode_report_blocks(<<>>, blocks), do: blocks
  defp decode_report_blocks(<<0x0, 0x0, 0x0, 0x0>>, blocks), do: blocks
  defp decode_report_blocks(<<>>), do: nil

  defp decode_report_blocks(<<bt::8, types::8, l::16, tsbc::binary>> = rp) do
    %{
      block_type: bt,
      type_specific: types,
      block_length: l,
      type_specific_block_contents: tsbc
    }
  end

  defp decode_report_blocks(
         <<ssrc::32, bseq::16, eseq::16, ato::32, timestamp::32, rest::binary>>,
         blocks
       ) do
    m = %{
      ssrc: ssrc,
      begin_seq: bseq,
      end_seq: eseq,
      arrival_time_offset: ato,
      timestamp: timestamp
    }

    decode_report_blocks(rest, blocks ++ m)
  end

  defp decode_report_blocks(_msg, _blocks), do: {:error, "could not parse message"}

  defp encode(_), do: nil
end
