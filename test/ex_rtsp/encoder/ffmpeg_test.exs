defmodule ExRtsp.Encoder.FfmpegTest do
  alias ExRtsp.Encoder.Ffmpeg
  use ExUnit.Case

  describe "ffmpeg" do
    test "setup/1 creates a command" do
      assert {:ok, port, filename} = Ffmpeg.setup(job_id: 11)
      assert filename == "/tmp/ffmpeg_socket_11"
      :ok = File.rm!("/tmp/ffmpeg_socket_11")
    end

    test "teardown/2 remove artifacts" do
      assert {:ok, port, filename} = Ffmpeg.setup(job_id: 11)
      assert true = Ffmpeg.teardown(port, 11)
      assert false == File.exists?("/tmp/ffmpeg_job_#{job_id}")
      assert false == File.exists?(filename)
    end
  end
end
