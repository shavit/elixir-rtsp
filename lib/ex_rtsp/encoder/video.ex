defmodule ExRtsp.Encoder.Video do
  @moduledoc """
  Documentation for `ExRtsp.Encoder.Video`.
  """

  defstruct [:f, :nri, :type]

  @doc """
  decode/1
  """
  def decode(<<f::1, nri::2, type::5, data::binary>>) do
    %{f: 1, nri: nri, type: type, data: data}
  end
end
