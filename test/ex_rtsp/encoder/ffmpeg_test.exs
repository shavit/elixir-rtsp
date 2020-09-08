defmodule ExRtsp.Encoder.FfmpegTest do
  alias ExRtsp.Encoder.Ffmpeg
  use ExUnit.Case

  describe "ffmpeg" do
    test "setup/1 creates a command" do
      assert {:ok, port} = Ffmpeg.setup(job_id: 11)
      :ok = File.rm!("/tmp/ffmpeg_socket_11")
    end
  end
end
