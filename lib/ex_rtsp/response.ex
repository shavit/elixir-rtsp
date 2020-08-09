defmodule ExRtsp.Response do
  @moduledoc """
  Documentation for `ExRtsp.Response`.
  """

  defstruct [
    :header,
    :body,
    :session
  ]

  @doc """
  new/1 decodes sdp messages

  The response will have this content type in the header
    Content-Type: application/sdp

  Each line has a character and value
  <character>=<value><CR><LF>
  https://en.wikipedia.org/wiki/Session_Description_Protocol

  m=  (media name and transport address)
  a=control:trackID=1
  """
  def new(resp) do
    case String.split(resp, "\r\n\r\n") do
      [header, body] -> decode(header, body)
      _ -> {:error, "invalid response"}
    end
  end

  def decode(header, body) do
    header = header |> String.split("\r\n") |> Enum.map(&String.split(&1, ":"))
    body = body |> String.split("\r\n") |> Enum.map(&String.split(&1, "="))

    if Enum.count(header) <= 1 or Enum.count(body) <= 1 do
      {:error, "invalid response"}
    else
      %__MODULE__{
        header: header,
        body: body,
        session: get_session_value(header)
      }
    end
  end

  defp get_session_value(header) do
    case header |> List.pop_at(0) |> elem(1) |> Enum.filter(&filter_session_key/1) do
      [[_, session]] -> String.trim(session)
      res -> nil
    end
  end

  defp filter_session_key(header_list) do
    "session" == header_list |> List.first() |> String.downcase()
  end
end
