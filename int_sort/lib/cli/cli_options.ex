defmodule IntSort.CLI.Options do
  @moduledoc """
  Represents a set of command line options
  """
  defstruct input_file: "",
            output_file: "",
            chunk_size: 10,
            keep_intermediate: false,
            silent: false

  # Define the stuct type definition
  @type t :: %IntSort.CLI.Options{
          input_file: String.t(),
          output_file: String.t(),
          chunk_size: pos_integer(),
          keep_intermediate: boolean(),
          silent: boolean()
        }

  @spec new(String.t(), String.t(), pos_integer(), boolean(), boolean()) ::
          IntSort.CLI.Options.t()
  def new(input_file, output_file, chunk_size, keep_intermediate, silent) do
    %IntSort.CLI.Options{
      input_file: input_file,
      output_file: output_file,
      chunk_size: chunk_size,
      keep_intermediate: keep_intermediate,
      silent: silent
    }
  end
end
