defmodule ExRtsp.SDP do
  @moduledoc """
  Documentation for `ExRtsp.SDP`.
  """

  defstruct [
    :version,
    :status,
    :status_code,
    :method,
    :resource,
    :header,
    :header_lines,
    :cseq,
    :body,
    :version,
    :name,
    :information,
    :media,
    :content_base,
    :session
  ]

  @crlf "\r\n\r\n"
  @version "RTSP/1.0"
end
