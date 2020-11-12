defmodule ExRtsp.RTPGroupTest do
  use ExUnit.Case
  doctest ExRtsp.RTPGroup
  alias ExRtsp.RTPGroup

  describe "rtp group" do
    test "start_link/1 starts a supervisor" do
      opts = [
	port: 3008
      ]
      assert {:ok, pid} = RTPGroup.start_link opts
    end
  end
end
