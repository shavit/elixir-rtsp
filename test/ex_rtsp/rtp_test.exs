defmodule ExRtsp.RTPTest do
  use ExUnit.Case
  doctest ExRtsp.RTP
  alias ExRtsp.RTP

  describe "rtp" do
    test "start_link/1 creates rtp client" do
      {:ok, pid} = RTP.start_link([])
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end

    test "init/1 state" do
      args = [
        port: 3000,
        job_id: "some job id",
        medium: "some medium"
      ]

      assert {:ok, state} = RTP.init(args)
      assert 3000 == Map.get(state, :port)
      assert nil != Map.get(state, :socket)
      assert nil != Map.get(state, :encoder_socket)
      assert nil != Map.get(state, :tmp_file)
      assert "some job id" == Map.get(state, :job_id)
      assert nil == Map.get(state, :timestamp)
      assert "some medium" == Map.get(state, :medium)
    end

    test "handle_call/3 stop call" do
      ref = "some ref"
      state = %{id: "some state"}
      assert {:reply, reply_1, reply_2} = RTP.handle_call(:stop, ref, state)
      assert "some state" == Map.get(reply_1, :id)
      assert "some state" == Map.get(reply_2, :id)
    end

    test "handle_info/5 udp call" do
      port = "some port"
      ip = {127, 0, 0, 1}
      udp_port = nil

      p = 0
      x = 0
      cc = 1
      m = 0
      pt = 96
      seq = 1
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      ssrc = 1234
      csrc = 1234
      b = <<>>
      msg = <<2::2, p::1, x::1, cc::4, m::1, pt::7, seq::16, timestamp::32, ssrc::32, b::binary>>

      state = %{
        timestamp: nil
      }

      assert {:noreply, state} = RTP.handle_info({:udp, port, ip, udp_port, msg}, state)
      assert state.timestamp == timestamp
    end

    test "terminate/2 reason" do
      File.rmdir("/tmp/ffmpeg_socket_")
      File.mkdir("/tmp/ffmpeg_socket_")
      encoder_socket = Port.open({:spawn, "sleep 3; echo 1"}, [:binary])

      state = %{
        encoder_socket: encoder_socket,
        job_id: nil
      }

      assert :normal == RTP.terminate(:normal, state)
      File.rmdir("/tmp/ffmpeg_socket_")
    end

    test "decode/1 decodes control messages" do
      [
        <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 195, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0>>,
        <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 205, 170, 192, 131, 18, 0, 7, 208, 16,
          0, 0, 1, 244, 0, 1, 94, 240>>
      ]
      |> Enum.each(fn x ->
        %{version: 2} = RTP.decode(x)
      end)
    end
  end
end
