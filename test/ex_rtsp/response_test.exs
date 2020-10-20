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

    assert %Response{} = resp = Response.new(resp)
    assert "1900" == resp.session
  end

  test "decode/1 decodes setup response" do
    resp =
      "RTSP/1.0 200 OK\r\nCSeq: 7\r\nCache-Control: no-store\r\nDate: Sun, 01 Jan 1970 00:00:00 UTC\r\nExpires: Sun, 01 Jan 1970 00:00:00 UTC\r\nPragma: no-cache\r\nServer: ExRtsp Server\r\nSession: 12345678\r\nTransport: RTP/AVP/UDP;unicast;source=127.0.0.1;client_port=3000-3001;server_port=45998-45999;ssrc=7jl51ep7q\r\n\r\n"

    assert %Response{} = resp = Response.new(resp)
    assert "12345678" == resp.session
  end

  test "decode/1 decodes media" do
    resp = "RTSP/1.0 200 OK\r
v=0
o=- 2955910 0 IN IP4 192.168.2.7
s=s0
u=www.evostream.com
e=contact@evostream.com
c=IN IP4 192.168.2.7
t=0 0
a=recvonly
a=control:*
a=range:npt=now-
m=audio 0 RTP/AVP 96
a=recvonly
a=rtpmap:96 mpeg4-generic/48000/1
a=control:trackID=1
a=fmtp:96 streamtype=5; profile-level-id=15; mode=AAC-hbr; config=1188; SizeLength=13; IndexLength=3; IndexDeltaLength=3;
m=video 0 RTP/AVP 97
a=recvonly
a=control:trackID=2
a=rtpmap:97 H264/90000
a=fmtp:97 profile-level-id=4d0029; packetiza\r\n\r\n"
    assert %Response{} = Response.new(resp)
  end
end
