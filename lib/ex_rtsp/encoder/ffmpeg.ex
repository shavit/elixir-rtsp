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
    ["/tmp", "ffmpeg_job_#{job_id}"] |> Path.join() |> File.mkdir()
    filename = Path.join(["/tmp", "ffmpeg_socket_#{job_id}"])
    File.rm(filename)
    {"", _exit_code} = System.cmd("mkfifo", [filename])

    port =
      Port.open(
        {:spawn,
         "ffmpeg -loglevel panic -hide_banner -i #{filename} -f hls /tmp/ffmpeg_job_#{job_id}/index.m3u8"},
        [:binary]
      )

    # true = Port.command(port, stream)

    {:ok, port, filename}
  end

  @doc """
  teardown/2 clean temporary files before closing
  """
  def teardown(port, job_id) do
    ["/tmp", "ffmpeg_socket_#{job_id}"] |> Path.join() |> File.rm!()
    ["/tmp", "ffmpeg_job_#{job_id}"] |> Path.join() |> File.rmdir!()
    true = Port.close(port)
  end

  def encode(tmp_file, stream) do
    :ok = File.write(tmp_file, stream)
  end

  def port_command(port, stream) do
    Port.command(port, stream)
  end
end
