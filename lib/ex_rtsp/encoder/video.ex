defmodule ExRtsp.Encoder.Video do
  @moduledoc """
  Documentation for `ExRtsp.Encoder.Video`.
  """

  defstruct [:f, :nri, :type]

  @nal_unit_type %{
    0 => :unspecified,
    1 => :non_idr,
    2 => :data_partition_a,
    3 => :data_partition_b,
    4 => :data_partition_c,
    5 => :idr_picture,
    6 => :sei,
    7 => :seq_parameter_set,
    8 => :picture_parameter_set,
    9 => :access_unit_delimeter,
    10 => :eos,
    11 => :eof,
    12 => :filter_data,
    13 => :seq_parameter_set_ext,
    14 => :prefix_nal,
    15 => :sub_seq_parameter_Set,
    16 => :reserved,
    17 => :reserved,
    18 => :reserved,
    19 => :aux_picture_without,
    20 => :extension,
    21 => :extension_depth_view,
    22 => :reserved,
    23 => :reserved,
    24 => :unspecified,
    25 => :unspecified,
    26 => :unspecified,
    27 => :unspecified,
    28 => :unspecified,
    29 => :unspecified,
    30 => :unspecified,
    31 => :unspecified
  }
  for {type, name} <- @nal_unit_type do
    @doc """
    decode/1
    """
    def decode(<<f::1, nri::2, unquote(type)::5, data::binary>>) do
      %{f: f, nri: nri, type: unquote(name), data: data}
    end
  end

  # @doc """
  # decode/1
  # """
  # def decode(<<f::1, nri::2, type::5, data::binary>>) do
  #   %{f: 1, nri: nri, type: type, data: data}
  # end
end
