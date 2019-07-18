defmodule LargeSort.Shared.IntegerFileBehavior do
  @callback integer_file_stream(String.t()) :: Enumerable.t()
  @callback read_stream(Enumerable.t()) :: Enumerable.t()
  @callback write_integers_to_stream(Enumerable.t(), Collectable.t()) :: Enumerable.t()
end
