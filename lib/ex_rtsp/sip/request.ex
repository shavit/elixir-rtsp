defmodule ExRtsp.SIP.Request do
  @moduledoc """
  Documentation for `ExRtsp.SIP.Request`.
  """

  defstruct [
    :version,
    :method,
    :resource,
    :header,
    :header_lines,
    :cseq,
    :body
  ]

  @type type :: :cache_control | :connection | :date | :via

  @type req_method ::
          :describe
          | :announce
          | :get_parameter
          | :options
          | :pause
          | :play
          | :record
          | :redirect
          | :setup
          | :set_parameter
          | :teardown
          | :extension_token

  @type req_header_fields ::
          :accept
          | :accept_encoding
          | :accept_language
          | :authorization
          | :from
          | :if_modified_since
          | :range
          | :referer
          | :user_agent

  @crlf "\r\n\r\n"
  @version "RTSP/1.0"

  @doc """
  new/1 creates a new request

  Example requset

  "DESCRIBE rtsp://127.0.0.1:1935 RTSP/1.0\r\cCSeq: 1\r\n\r\n"
  """
  def new(opts) do
    method = opts |> Keyword.get(:method, :options) |> get_req_method()
    resource = Keyword.get(opts, :url, "*")

    %__MODULE__{
      body: Keyword.get(opts, :body, []),
      header: method <> " " <> resource <> " " <> @version,
      header_lines: [
        opts |> Keyword.get(:cseq, 1) |> header_cseq(),
        Keyword.get(opts, :transport),
        opts |> Keyword.get(:user_agent) |> header_user_agent(),
        opts |> Keyword.get(:session) |> header_session(),
        opts |> Keyword.get(:range) |> header_range(),
        opts |> Keyword.get(:accept) |> header_accept(),
        opts |> Keyword.get(:parameter) |> header_parameter()
      ],
      method: method,
      resource: resource,
      version: @version
    }
  end

  @doc """
  encode/1 encodes request to binary
  """
  def encode(%__MODULE__{} = req) do
    encode_header(req) <> encode_body(req)
  end

  defp encode_header(%__MODULE__{header: header, header_lines: lines}) do
    lines = lines |> Enum.filter(&(!is_nil(&1))) |> Enum.join("\r\n")
    header <> "\r\n" <> lines <> @crlf
  end

  defp get_req_method(method) do
    %{
      describe: "DESCRIBE",
      announce: "ANNOUNCE",
      get_parameter: "GET_PARAMETER",
      options: "OPTIONS",
      pause: "PAUSE",
      play: "PLAY",
      record: "RECORD",
      redirect: "REDIRECT",
      setup: "SETUP",
      set_parameter: "SET_PARAMETER",
      teardown: "TEARDOWN",
      extension_token: ""
    }
    |> Map.get(method, {:error, "invalid method"})
  end

  defp header_accept(nil), do: nil
  defp header_accept(body), do: "Accept: #{body}"

  defp header_cseq(n), do: "CSeq: #{n}"

  defp header_user_agent(nil), do: header_user_agent("ExRtsp")
  defp header_user_agent(name), do: "User-Agent: #{name}"

  defp header_session(nil), do: nil
  defp header_session(n), do: "Session: #{n}"

  defp header_range(nil), do: nil
  defp header_range({a, b}), do: "Range: npt=#{a}-#{b}"
  defp header_range({a}), do: "Range: npt=#{a}-"

  defp header_parameter(nil), do: nil
  defp header_parameter([{k, v}]), do: "#{k}: #{v}"

  def option_set_transport(opt), do: "Transport: #{opt}"

  def option_set_transport_default,
    do: option_set_transport("RTP/AVP/UDP;unicast;client_port=3000-3001")

  defp encode_body(%__MODULE__{body: body}) do
    Enum.join(body, "\r\n")
  end

  @doc """
  Create a SETUP request

  The response will have the session ID, that will be used in
    the PLAY request later on
  Session: <SESSION>
  """
  def new_setup(_resp) do
    url = "rtsp://host/s0/trackID=2"
    new(method: :setup, url: url, transport: option_set_transport_default())
  end

  @doc """
  decode/1 decodes a message
  """
  def decode(encoded_message) do
    case encoded_message |> String.split("\r\n") |> Enum.filter(&(&1 != "")) do
      [header | lines] ->
        %__MODULE__{
          method: decode_method(header),
          resource: decode_resource(header),
          version: decode_version(header),
          header: header,
          header_lines: lines,
          cseq: decode_cseq(lines)
        }

      _ ->
        {:error, "invalid request"}
    end
  end

  defp decode_method(header) do
    header |> String.split(" ") |> Enum.at(0)
  end

  defp decode_resource(header) do
    header |> String.split(" ") |> Enum.at(1)
  end

  defp decode_version(header) do
    header |> String.split(" ") |> Enum.at(2)
  end

  defp decode_cseq(header_lines) do
    header_lines
    |> Enum.map(fn x -> String.split(x, ": ") end)
    |> Enum.filter(fn [k, _v] -> "cseq" == String.downcase(k) end)
    |> List.first()
    |> List.last()
    |> String.to_integer()
  end
end
