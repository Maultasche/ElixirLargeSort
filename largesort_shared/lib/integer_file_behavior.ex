defmodule LargeShort.Shared.IntegerFileBehavior do
  @callback create_integer_file_stream(String.t()) :: Enumerable.t()
  @callback write_integers_to_stream(Enumerable.t(), Collectable.t()) :: Enumerable.t()
end
