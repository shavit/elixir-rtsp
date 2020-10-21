defmodule ExRtsp.Response do
  @moduledoc """
  Documentation for `ExRtsp.Response`.
  """

  defstruct [
    :status,
    :header,
    :body,
    :media,
    :content_base,
    :rtp_info,
    :session,
    :server_rtp_port,
    :server_rtsp_port
  ]

  @doc """
  new/1 decodes sdp messages

  The response will have this content type in the header
    Content-Type: application/sdp

  Each line has a character and value
  <character>=<value><CR><LF>
  https://tools.ietf.org/html/rfc4566
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

    if Enum.count(header) <= 1 or !has_valid_body(body) do
      {:error, "invalid response"}
    else
      %__MODULE__{
        header: header,
        body: decode_body(body),
        status: get_status_code(header),
        content_base: get_content_base_value(header),
        rtp_info: get_rtp_value(header),
        session: get_session_value(header),
        server_rtp_port: header |> get_server_ports() |> Enum.at(0),
        server_rtsp_port: header |> get_server_ports() |> Enum.at(1)
      }
    end
  end

  defp decode_body(kv_list) do
    kv_list
    |> Enum.reduce(%{prev: nil}, fn [k | v], acc ->
      if k == "a" && Enum.any?(v) do
        Map.update(acc, acc.prev, [v], fn x -> x ++ [v] end)
      else
        mkey =
          case List.first(v) do
            nil -> nil
            v -> v |> String.split() |> List.first()
          end

        %{acc | prev: mkey}
      end
    end)
  end

  defp has_vaild_body([""]), do: false

  defp has_valid_body(body) when is_list(body) do
    Enum.reduce(body, true, fn a, acc ->
      if acc == true do
        a == [""] or Enum.count(a) >= 2
      else
        acc
      end
    end)
  end

  defp has_vaild_body(_), do: false

  defp get_status_code([[h | _h2] | _t]) do
    h |> String.split(" ") |> Enum.at(1) |> String.to_integer()
  end

  defp get_status_code(_header), do: nil

  defp get_content_base_value(header) do
    case header |> Enum.filter(&filter_content_base_key/1) |> List.first() do
      nil -> nil
      parts -> get_content_base_value_url(parts)
    end
  end

  defp get_content_base_value_url([_key | url_parts]) do
    url_parts
    |> Enum.join(":")
    |> String.trim()
  end

  defp get_content_base_value_url(_url_partts), do: nil

  defp filter_content_base_key(header_list) do
    "content-base" == header_list |> List.first() |> String.downcase()
  end

  defp get_rtp_value(header) do
    case header |> Enum.filter(&filter_rtp_info_key/1) |> List.first() do
      nil -> nil
      parts -> get_rtp_value_url(parts)
    end
  end

  defp get_rtp_value_url([_key | url_parts]) when is_list(url_parts) do
    url_parts
    |> Enum.join(":")
    |> String.split("url=")
    |> List.last()
    |> String.trim()
  end

  defp get_rtp_value_url(_url_parts), do: nil

  defp filter_rtp_info_key(header_list) do
    "rtp-info" == header_list |> List.first() |> String.downcase()
  end

  defp get_session_value(header) do
    case header |> List.pop_at(0) |> elem(1) |> Enum.filter(&filter_session_key/1) do
      [[_, session]] -> String.trim(session)
      _ -> nil
    end
  end

  defp filter_session_key(header_list) do
    "session" == header_list |> List.first() |> String.downcase()
  end

  defp get_server_ports(header) do
    case get_server_header_pair(header, "transport") do
      [[_ | [transport]]] ->
        transport
        |> String.trim()
        |> String.split(";")
        |> Enum.filter(fn x ->
          "server_port" == x |> String.split("=") |> List.first() |> String.downcase()
        end)
        |> Enum.map(fn x ->
          x |> String.split("=") |> List.last()
        end)
        |> get_server_ports_from_pair

      _ ->
        []
    end
  end

  defp get_server_ports_from_pair([ports]) do
    ports |> String.split("-") |> Enum.map(&String.to_integer/1)
  end

  defp get_server_ports_from_pair(nil), do: []

  defp get_server_header_pair(header_list, key) do
    header_list
    |> List.pop_at(0)
    |> elem(1)
    |> filter_server_header_pair(key)
  end

  defp filter_server_header_pair(header_list, key) do
    Enum.filter(header_list, fn x ->
      String.downcase(key) == x |> List.pop_at(0) |> elem(0) |> String.downcase()
    end)
  end
end
