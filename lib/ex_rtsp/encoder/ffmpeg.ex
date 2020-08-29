defmodule ExRtsp.Encoder.Ffmpeg do
  @moduledoc """
  Documentation for `ExRtsp.Encoder.Ffmpeg`.
  """

  @doc """
  setup/1 creates the encoder

    * Check if binaries and dependencies are installed
    * Create temporary files
  """
  def setup(opts) do
    job_id = Keyword.get(opts, :job_id, 0)
    File.mkdir("/tmp/ffmpeg_job_#{job_id}")
    filename = "/tmp/ffmpeg_socket_#{job_id}"
    {"", _exit_code} = System.cmd("mkfifo", [filename])

    port =
      Port.open({:spawn, "ffmpeg -loglevel panic -hide_banner -i #{filename} -f hls /tmp/ffmpeg_job_#{job_id}/index.m3u8"}, [])

    {:ok, port}
  end

  @doc """
  teardown/1 clean temporary files before closing
  """
  def teardown(port) do
    File.rm!("/tmp/ffmpeg_socket_0")
    File.rmdir!("/tmp/ffmpeg_job_0")
    true = Port.close(port)
  end

  def encode(port, stream) do
    true = Port.command(port, stream)
  end
end
