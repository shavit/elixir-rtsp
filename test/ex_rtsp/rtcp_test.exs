defmodule ExRtsp.RTCPTest do
  use ExUnit.Case
  doctest ExRtsp.RTCP
  alias ExRtsp.RTCP

  describe "rtcp" do
    test "start_link/1 creates rctp client" do
      {:ok, pid} = RTCP.start_link([])
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end

    test "decode/1 decodes control messages" do
      [
        <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 195, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0>>,
        <<128, 200, 0, 6, 128, 173, 212, 19, 226, 254, 93, 205, 170, 192, 131, 18, 0, 7, 208, 16,
          0, 0, 1, 244, 0, 1, 94, 240>>
      ]
      |> Enum.each(fn x ->
        %{version: 2} = RTCP.decode(x)
      end)
    end

    test "decode/1 decodes packet type sr" do
      [
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 105, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 115, 170, 126, 249, 219, 0, 7, 207, 224,
          0, 0, 1, 244, 0, 1, 94, 233>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 126, 85, 63, 124, 237, 0, 15, 159, 239,
          0, 0, 3, 232, 0, 2, 189, 210>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 137, 0, 0, 0, 0, 0, 23, 112, 0, 0, 0, 5,
          220, 0, 4, 28, 188>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 147, 170, 126, 249, 219, 0, 31, 63, 223,
          0, 0, 7, 208, 0, 5, 123, 165>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 158, 85, 63, 124, 237, 0, 39, 15, 240,
          0, 0, 9, 196, 0, 6, 218, 142>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 169, 0, 0, 0, 0, 0, 46, 224, 0, 0, 0,
          11, 184, 0, 8, 57, 120>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 179, 170, 126, 249, 219, 0, 54, 175,
          224, 0, 0, 13, 172, 0, 9, 152, 97>>,
        <<128, 200, 0, 6, 128, 74, 111, 152, 227, 6, 127, 190, 85, 63, 124, 237, 0, 62, 127, 240,
          0, 0, 15, 160, 0, 10, 247, 74>>
      ]
      |> Enum.each(fn x ->
        %{version: 2, packet_type: :sr, padding: false} = RTCP.decode(x)
      end)
    end
  end
end
