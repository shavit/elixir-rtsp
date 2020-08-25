defmodule ExRtsp.RequestTest do
  alias ExRtsp.Request
  use ExUnit.Case

  describe "request" do
    test "new/1 creates a request" do
      assert %Request{} = Request.new([])

      opts = [
        cseq: 4,
        host: "0.0.0.0",
        port: "4000"
      ]

      req = Request.new(opts)

      assert %ExRtsp.Request{
               body: [],
               header: "OPTIONS * RTSP/1.0",
               header_lines: ["CSeq: 4", nil, "User-Agent: ExRtsp", nil, nil, nil]
             } == req
    end

    test "encode/1 encodes a request to binary" do
      opts = [
        cseq: 4,
        host: "0.0.0.0",
        port: "4000"
      ]

      req = Request.new(opts)
      assert "OPTIONS * RTSP/1.0\r\nCSeq: 4\r\nUser-Agent: ExRtsp\r\n\r\n" == Request.encode(req)
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
  end
end
