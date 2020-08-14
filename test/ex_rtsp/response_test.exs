defmodule ExRtsp.ResponseTest do
  alias ExRtsp.Response
  use ExUnit.Case

  test "decode/1 handle invalid responses" do
    assert {:error, _reason} = Response.new("header\r\n")
    assert {:error, _reason} = Response.new("header\r\n\r\nbody")
    assert {:error, _reason} = Response.new("header\r\nbody")

    assert {:error, _reason} =
             Response.new("some response\r\nsome invalid header\r\n\r\ninvalid body")
  end

  test "decode/1 decodes header and body" do
    resp =
      "RTSP/1.0 200 OK\r\nCSeq: 4\r\nContent-Base: rtsp://127.0.0.1:554/stream_1/\r\nContent-Type: application/sdp\r\nSession: 1900\r\n\r\nv=0\r\no=- 286730 0 IN IP4 127.0.0.1\r\ns=s0\r\nc=IN IP4 127.0.0.1\r\nt=0 0\r\na=recvonly\r\na=control:*\r\na=range:npt=now-\r\nm=audio 0 RTP/AVP 96\r\na=recvonly\r\na=rtpmap:96 mpeg4-generic/48000/1\r\na=control:trackID=2\r\nm=video 0 RTP/AVP 97\r\na=recvonly\r\na=control:trackID=2\r\na=rtpmap:97 H264/90000\r\n"

    resp = Response.new(resp)
    assert "1900" == resp.session
  end
end
