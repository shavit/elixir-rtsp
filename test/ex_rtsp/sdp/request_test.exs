defmodule ExRtsp.SDP.RequestTest do
  use ExUnit.Case
  doctest ExRtsp.SDP.Request
  alias ExRtsp.SDP.Request

  describe "request" do
    test "read/1 creates a new request" do
      assert %Request{} = Request.read([])

      opts = [
        cseq: 4,
        host: "0.0.0.0",
        port: "4000"
      ]

      req = Request.read(opts)

      assert %Request{
               body: [],
               header: "OPTIONS * RTSP/1.0",
               header_lines: ["CSeq: 4", nil, "User-Agent: ExRtsp", nil, nil, nil, nil],
               method: "OPTIONS",
               resource: "*",
               version: "RTSP/1.0"
             } == req
    end

    test "encode/1 encodes a request to binary" do
      opts = [
        cseq: 4,
        host: "0.0.0.0",
        port: "4000"
      ]

      req = Request.read(opts)
      assert "OPTIONS * RTSP/1.0\r\nCSeq: 4\r\nUser-Agent: ExRtsp\r\n\r\n" == Request.write(req)
    end

    test "option_set_transport/1 returns a transport option in binary format" do
      assert "Transport: some transport option" ==
               Request.option_set_transport("some transport option")
    end

    test "optino_set_transport_default/0 returns a default transport option" do
      assert "Transport: RTP/AVP/UDP;unicast;client_port=3000-3001" ==
               Request.option_set_transport_default()
    end

    test "new_setup/1 creates a setup request" do
      assert %Request{} = Request.new_setup([])
    end

    test "decode/1 decodes a message" do
      [
        {<<>>, {:error, "invalid request"}},
        {"DESCRIBE rtsp://127.0.0.1:8555/s0 RTSP/1.0\r\nCSeq: 0\r\nUser-Agent: ExRtsp\r\n\r\n",
         %Request{
           header: "DESCRIBE rtsp://127.0.0.1:8555/s0 RTSP/1.0",
           header_lines: ["CSeq: 0", "User-Agent: ExRtsp"],
           method: "DESCRIBE",
           resource: "rtsp://127.0.0.1:8555/s0",
           version: "RTSP/1.0",
           cseq: 0
         }},
        {"SETUP rtsp://127.0.0.1:8555/s0 RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: ExRtsp\r\n\r\n",
         %Request{
           header: "SETUP rtsp://127.0.0.1:8555/s0 RTSP/1.0",
           header_lines: ["CSeq: 1", "User-Agent: ExRtsp"],
           method: "SETUP",
           resource: "rtsp://127.0.0.1:8555/s0",
           version: "RTSP/1.0",
           cseq: 1
         }}
      ]
      |> Enum.each(fn {l, r} -> assert Request.decode(l) == r end)
    end
  end
end
