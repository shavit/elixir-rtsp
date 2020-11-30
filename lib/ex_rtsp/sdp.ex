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
    :body
  ]
end
