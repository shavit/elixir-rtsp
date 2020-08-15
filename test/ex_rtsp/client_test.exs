defmodule ExRtsp.ClientTest do
  alias ExRtsp.Client
  use ExUnit.Case

  describe "client" do
    test "start_link/1 creates a new client" do
      {:ok, pid} = Client.start_link(host: "127.0.0.1")
      assert true == Process.alive?(pid)
      assert true == Process.exit(pid, :normal)
    end

    test "init/1 initialize the client state" do
      assert {:ok, %{abs_path: "/stream-1", conn: nil, cseq: 0, host: "0.0.0.0", port: 4000},
              {:continue, :dial_rtsp}} =
               Client.init(abs_path: "/stream-1", host: "0.0.0.0", port: 4000)
    end
  end
end
