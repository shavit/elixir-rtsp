# ExRtsp

[![Build Status](https://travis-ci.org/shavit/elixir-rtsp.svg?branch=master)](https://travis-ci.org/shavit/elixir-rtsp)

> RTSP library

Features:
  - [x] SIP decoder
  - [ ] SIP encoder
  - [x] RTSP Client
  - [ ] RTSP Server
  - [ ] RTP transmission
  - [ ] RTCP transmission

# Quick start

Create a client
```
iex> {:ok, pid} = ExRtmp.Client.start_link host: "127.0.0.1", port: 554
```
```
CSeq: 0
Cache-Control: no-store
...
```

Send a request
```
iex> req = ExRtsp.Request.new method: :options
iex> GenServer.call pid, {:send_req, msg}
```
```
CSeq: 1
Cache-Control: no-store
...
```

## Installation

If [available in Hex](https://hex.pm/packages/ex_rtsp), the package can be installed
by adding `ex_rtsp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_rtsp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hex.pm/packages/ex_rtsp). Once published, the docs can
be found at [https://hexdocs.pm/ex_rtsp](https://hex.pm/packages/ex_rtsp).

