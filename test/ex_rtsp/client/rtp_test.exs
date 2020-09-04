defmodule ExRtsp.Client.RTPTest do
  use ExUnit.Case
  doctest ExRtsp.Client.RTP
  alias ExRtsp.Client.RTP

  describe "rtp" do
    test "start_link/1 creates rtp client" do
      {:ok, pid} = RTP.start_link([])
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end
  end
end
