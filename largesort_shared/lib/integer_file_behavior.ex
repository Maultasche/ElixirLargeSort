defmodule LargeSort.Shared.IntegerFileBehavior do
  @callback integer_file_stream(String.t()) :: Enumerable.t()
  @callback read_stream(Enumerable.t()) :: Enumerable.t()
  @callback write_integers_to_stream(Enumerable.t(), Collectable.t()) :: Enumerable.t()
  @callback integer_count(Enumerable.t()) :: non_neg_integer()
  @callback read_device!(String.t()) :: IO.device()
  @callback write_device!(String.t()) :: IO.device()
  @callback read_integer(IO.device()) :: integer() | IO.no_data()
  @callback write_integer(IO.device(), integer()) :: :ok
  @callback integers_to_lines(Enum.t()) :: Enum.t()
end
