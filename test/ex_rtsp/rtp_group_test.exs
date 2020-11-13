defmodule ExRtsp.RTPGroupTest do
  use ExUnit.Case
  doctest ExRtsp.RTPGroup
  alias ExRtsp.RTPGroup

  describe "rtp group" do
    test "start_link/1 starts a supervisor" do
      opts = [
        port: 3008
      ]

      assert {:ok, pid} = RTPGroup.start_link(opts)
      children = Supervisor.which_children(pid)
      assert 2 == Enum.count(children)

      Enum.each(children, fn {_module, _pid, child, opts} ->
        assert :worker == child
        assert is_list(opts)
      end)
    end
  end
end
