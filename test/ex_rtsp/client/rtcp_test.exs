defmodule ExRtsp.Client.RTCPTest do
  use ExUnit.Case
  doctest ExRtsp.Client.RTCP
  alias ExRtsp.Client.RTCP

  describe "rtcp" do
    test "start_link/1 creates rctp client" do
      {:ok, pid} = RTCP.start_link([])
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end
  end
end
