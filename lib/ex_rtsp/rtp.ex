defmodule ExRtsp.RTP do
  @moduledoc """
  Documentation for `ExRtsp.RTP`.
  """
  use GenServer
  require Logger
  alias ExRtsp.Encoder.Ffmpeg
  alias ExRtsp.Encoder.Video

  # https://tools.ietf.org/html/rfc3551#page-32
  payload_types =
    %{
      0 => :pcmu,
      1 => :reserved,
      2 => :reserved,
      3 => :gsm,
      4 => :g732,
      5 => :dvi4,
      6 => :dvi5,
      7 => :lpc,
      8 => :pcma,
      9 => :g722,
      10 => :l16,
      11 => :l16,
      12 => :qcelp,
      13 => :cn,
      14 => :mpa,
      15 => :g728,
      16 => :dvi4,
      17 => :dvi4,
      18 => :g729,
      19 => :reserved,
      20 => :unassigned,
      21 => :unassigned,
      22 => :unassigned,
      23 => :unassigned,
      24 => :unassigned,
      25 => :celb,
      26 => :jpeg,
      27 => :unassigned,
      28 => :nv,
      29 => :unassigned,
      30 => :unassigned,
      31 => :h261,
      32 => :mpv,
      33 => :mp2t,
      34 => :h263,
      (35..71) => :unassigned,
      (72..76) => :reserved,
      (77..95) => :unassigned,
      (96..127) => :dynamic
    }
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      case k do
        %Range{} ->
          k
          |> Enum.to_list()
          |> Enum.reduce(%{}, fn a, acc -> Map.put(acc, a, v) end)
          |> Enum.into(acc)

        k ->
          Enum.into(acc, %{k => v})
      end
    end)

  @payload_types payload_types

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
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
      job_id: Keyword.get(opts, :job_id),
      timestamp: nil,
      medium: Keyword.get(opts, :medium)
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
    # Ffmpeg.encode(state.tmp_file, body)
    state = handle_message(msg_decoded, state)
    # Logger.info("[Client.RTP] #{inspect(msg_decoded)}")
    # Logger.info("[Client.RTP] payload: #{inspect(msg_decoded.payload)}")

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
      payload_type: get_payload_type(pt),
      sequence: seq,
      timestamp: tm,
      ssrc_identifier: ssrc,
      payload: decode_payload(b)
    }
  end

  # https://tools.ietf.org/html/rfc6184
  # https://tools.ietf.org/html/rfc3984
  # https://tools.ietf.org/html/rfc3640
  defp decode_payload(<<f::1, nri::2, type::5, b::binary>>) do
    b |> decode_payload_data() |> Enum.into(%{f: f, nri: nri, type: type})
  end

  defp decode_payload(_payload), do: :invalid

  # https://tools.ietf.org/html/rfc2435
  defp decode_payload_data(<<t1::8, offset::24, t2::8, q::8, w::8, h::8, b::binary>>) do
    %{
      type_specific: t1,
      fragment_offset: offset,
      type: t2,
      quantization: q,
      width: w,
      height: h,
      data: b
    }
  end

  # defp decode_payload_data(_data), do: :invalid
  defp decode_payload_data(_data), do: %{}

  defp handle_message(%{timestamp: timestamp}, state) do
    %{state | timestamp: timestamp}
  end

  defp get_payload_type(n), do: Map.get(@payload_types, n)
end
