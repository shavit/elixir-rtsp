defmodule ExRtsp.Request do
  @moduledoc """
  Documentation for `ExRtsp.Request`.
  """

  defstruct [
    :header,
    :header_lines,
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
        Keyword.get(opts, :session)
      ]
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

  defp header_accept(body), do: "Accept: #{body}"

  defp header_cseq(n), do: "CSeq: #{n}"

  def option_set_transport(opt), do: "Transport: #{opt}"

  def option_set_transport_default,
    do: option_set_transport("RTP/AVP;unicast;client_port=3000-3001")

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
    url = "rtsp://host/s0/trackID=1"
    new(method: :setup, url: url, transport: option_set_transport_default())
  end
end
