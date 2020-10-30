defmodule ExRtsp.Response do
  @moduledoc """
  Documentation for `ExRtsp.Response`.

  SDP: Session Description Protocol
  """

  defstruct [
    :status,
    :name,
    :information,
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
	name: get_session_name(body),
        header: header,
        body: decode_body(body),
        media: decode_media(body),
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

  defp decode_media(kv_list) do
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
    |> Enum.reduce(%{}, fn {k, v} = a, acc ->
      case decode_media_property(a) do
        %{} = m -> Enum.into(%{k => m}, acc)
        _ -> acc
      end
    end)
  end

  defp decode_media_property({"audio", v}) do
    %{
      track_id: decode_media_get_track(v),
      rtpmap: decode_media_get_rtpmap(v),
      fmtp: decode_media_get_fmtp(v)
    }
  end

  defp decode_media_property({"video", v}) do
    %{
      track_id: decode_media_get_track(v),
      rtpmap: decode_media_get_rtpmap(v),
      fmtp: decode_media_get_fmtp(v)
    }
  end

  defp decode_media_property({:prev, v}), do: nil
  defp decode_media_property({k, v}), do: {k, v}

  defp decode_media_get_track(props) when is_list(props) do
    props
    |> Enum.filter(fn [h | t] -> h == "control:trackID" end)
    |> Enum.map(fn [k, v] -> String.to_integer(v) end)
    |> List.first()
  end

  defp decode_media_get_rtpmap(props) when is_list(props) do
    props
    |> Enum.filter(fn x -> x |> List.first() |> String.contains?("rtpmap") end)
    |> Enum.map(&List.first/1)
    |> List.first()
    |> String.split()
    |> List.last()
  end

  defp decode_media_get_fmtp(props) when is_list(props) do
    case props
         |> Enum.filter(fn [h | _t] -> h |> String.contains?("fmtp") end)
         |> List.first() do
      [_h | _t] = l ->
        l
        |> Enum.join(" ")
        |> String.split(";")
        |> Enum.map(&decode_media_get_fmtp_pair/1)
        |> List.flatten()
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&String.trim/1)
        |> Enum.map(&(&1 |> String.split() |> List.to_tuple()))

      l ->
        l
    end
  end

  defp decode_media_get_fmtp_pair(x) do
    if String.contains?(x, "fmtp") do
      [a, b, c] = String.split(x, " ")

      [
        a |> String.split(":") |> Enum.join(" "),
        Enum.join([b, c], " ")
      ]
    else
      x
    end
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

  defp get_session_name(body) when is_list(body) do
    body
    |> Enum.filter(fn [k | _v] -> k == "s" end)
    |> List.first()
    |> List.last()
  end

  defp get_session_name(_body), do: nil
  defp get_session_information(_body), do: nil

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
