defmodule ExRtsp.ClientTest do
  use ExUnit.Case
  doctest ExRtsp.Client
  alias ExRtsp.Client

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

    test "handle_continue/2 handle connection error" do
      state = %{
        host: "127.0.0.1",
        port: 554,
        conn: nil
      }

      assert {:noreply, state} = Client.handle_continue(:dial_rtsp, state)
      assert "127.0.0.1" == state.host
      assert 554 == state.port
      assert nil == state.conn
    end

    test "handle_call/3 describe" do
      state = %{
        abs_path: "/stream-test",
        cseq: 1,
        host: "127.0.0.1",
        port: 554,
        conn: nil
      }

      opts = []
      ref = "some ref"
      assert {:reply, res, state} = Client.handle_call({:describe, opts}, ref, state)
      assert {:error, "need to reconnect"} == res
      assert nil == state.conn
      assert 1 == state.cseq
      assert "127.0.0.1" == state.host
      assert 554 == state.port
    end

    test "handle_call/3 setup" do
      state = %{
        abs_path: "/stream-test",
        content_base: "rtsp://127.0.0.1:554/",
        cseq: 1,
        host: "127.0.0.1",
        media: [
          %{
            track_id: "1"
          }
        ],
        port: 554,
        conn: nil
      }

      opts = []
      ref = "some ref"
      assert {:reply, res, state} = Client.handle_call({:setup, opts}, ref, state)
      assert :ok == res
      assert "/stream-test" == state.abs_path
      assert nil == state.conn
      assert "rtsp://127.0.0.1:554/" == state.content_base
    end
  end
end
