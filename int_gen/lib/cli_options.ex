defmodule IntGen.CLI.Options do
  @moduledoc """
  Represents a set of command line options
  """
  defstruct lower_bound: 0,
            upper_bound: 0,
            count: 0,
            output_file: ""

  # Define the stuct type definition
  @type t :: %IntGen.CLI.Options{
          lower_bound: integer(),
          upper_bound: integer(),
          count: non_neg_integer(),
          output_file: String.t()
        }

  @spec new(non_neg_integer(), integer(), integer(), String.t()) :: IntGen.CLI.Options.t()
  def new(count, lower_bound, upper_bound, output_file) do
    %IntGen.CLI.Options{
      count: count,
      lower_bound: lower_bound,
      upper_bound: upper_bound,
      output_file: output_file
    }
  end
end
