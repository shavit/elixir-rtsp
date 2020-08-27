defmodule ExRtsp.Encoder do
  @moduledoc """
  Documentation for `ExRtsp.Encoder`.
  """
  @callback encode(binary()) :: {:ok, term} | {:error, String.t()}
end
