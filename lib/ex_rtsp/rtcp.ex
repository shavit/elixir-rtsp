defmodule ExRtsp.RTCP do
  @moduledoc """
  Documentation for `ExRtsp.RTCP`.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    port = Keyword.get(opts, :port, 3001)
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])

    state = %{
      port: port,
      socket: socket,
      server: Keyword.get(opts, :server),
      timestamp: nil,
      ssrc: nil,
      medium: Keyword.get(opts, :medium)
    }

    {:ok, state}
  end

  def handle_call(:stop, _ref, state) do
    Logger.info("[Client.RTCP] stop")

    {:reply, state, state}
  end

  def handle_info({:udp, port, _ip, _udp_port, msg}, state) do
    Logger.info("[Client.RTCP] New message: #{inspect(msg)}")
    Logger.info("[Client.RTCP] #{inspect(decode(msg))}")
    decoded = decode(msg)
    state = handle_message(decoded, state)

    {:noreply, state}
  end

  def decode(<<v::2, p::1, rc::5, 200::8, l::16, ssrc::32, rp::binary>>) do
    <<ntp_tm::64, rtp_tm::32, spc::32, soc::32, rp::binary>> = rp

    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :sr,
      length: l,
      ssrc: ssrc,
      sender_information: %{
        ntp_timestamp: ntp_tm,
        rtp_timestamp: rtp_tm,
        sender_packet_count: spc,
        sender_octet_count: soc
      },
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  def decode(<<v::2, p::1, rc::5, 201::8, l::16, ssrc::32, rp::binary>>) do
    m = %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :rp,
      length: l,
      ssrc: ssrc
      #      report_blocks: decode_report_blocks(rp, [])
    }

    report_blocks = if rc == 0, do: [], else: decode_report_blocks(rp, [])
    Map.put(m, :report_blocks, report_blocks)
  end

  def decode(<<v::2, p::1, rc::5, 202::8, l::16, ssrc::32, rp::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :sdes,
      length: l,
      ssrc: ssrc,
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  def decode(<<v::2, p::1, rc::5, 203::8, l::16, ssrc::32, rp::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :bye,
      length: l,
      ssrc: ssrc,
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  def decode(<<v::2, p::1, rc::5, 204::8, l::16, ssrc::32, rp::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :app,
      length: l,
      ssrc: ssrc,
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  def decode(<<v::2, p::1, rc::5, _pt::8, l::16, ssrc::32, rp::binary>>) do
    %{
      version: v,
      padding: p == 1,
      reception_report_count: rc,
      packet_type: :undefined,
      length: l,
      ssrc: ssrc,
      report_blocks: decode_report_blocks(rp, [])
    }
  end

  defp decode_report_blocks(<<>>, blocks), do: blocks
  defp decode_report_blocks(<<0x0, 0x0, 0x0, 0x0>>, blocks), do: blocks

  defp decode_report_blocks(
         <<ssrc::32, fl::8, cnopl::24, ehsn::32, ij::32, rest::binary>>,
         blocks
       ) do
    m = %{
      ssrc_identifier: ssrc,
      fraction_lost: fl,
      cumulative_packet_lost: cnopl,
      extended_highest_seq_n: ehsn,
      interarrival_jitter: ij
    }

    decode_report_blocks(rest, blocks ++ [m])
  end

  defp decode_report_blocks(_msg, _blocks), do: {:error, "could not parse message"}

  defp handle_message(%{packet_type: :bye}, state) do
    GenServer.cast(state.server, {:send_seq, bye("stream ended")})
    Process.exit(self(), :normal)
    state
  end

  defp handle_message(%{packet_type: :sr, sender_information: info, ssrc: ssrc}, state) do
    %{state | timestamp: info.rtp_timestamp, ssrc: ssrc}
  end

  defp handle_message(_msg, state), do: state

  defp bye(reason) do
    v = 2
    p = 0
    rc = 0
    l = byte_size(reason)
    ssrc = 0
    rp = <<>>
    <<v::2, p::1, rc::5, 203::8, l::16, ssrc::32, rp::binary>>
  end
end
