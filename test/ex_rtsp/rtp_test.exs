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

    test "decode/1 decodes control messages" do
      tests =
        [
          <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 195, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0>>,
          <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 205, 170, 192, 131, 18, 0, 7, 208,
            16, 0, 0, 1, 244, 0, 1, 94, 240>>
        ]
        |> Enum.each(fn x ->
          %{version: 2} = RTP.decode(x)
        end)
    end
  end
end
