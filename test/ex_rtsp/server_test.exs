defmodule ExRtsp.ServerTest do
  alias ExRtsp.Server
  use ExUnit.Case

  describe "server" do
    test "start_link/1 creates a new server" do
      {:ok, pid} = Server.start_link(port: 5540)
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end

    test "init/1 initialize the client state" do
      assert {:ok, %{socket: socket, port: 5543}} = Server.init(port: 5543)
      assert is_nil(socket) == false
    end
  end
end
