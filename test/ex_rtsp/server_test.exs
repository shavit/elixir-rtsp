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
      assert {:ok, %{lsock: lsock, sock: nil, port: 5543}, {:continue, :accept_connections}} =
               Server.init(port: 5543)

      assert is_nil(lsock) == false
    end

    test "handle_info/2 handles describe message" do
      from = nil
      msg = "DESCRIBE rtsp://127.0.0.1:8555/s0 RTSP/1.0\r\nCSeq: 0\r\nUser-Agent: ExRtsp\r\n\r\n"

      state = %{
        port: 8555,
        lsock: nil,
        sock: nil
      }

      assert {:noreply, %{lsock: nil, port: 8555, sock: nil}} =
               Server.handle_info({:tcp, from, msg}, state)
    end
  end
end
