defmodule IntGen.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  alias IntGen.CLI.Args

  @type parsed_args() :: {keyword(), list(String.t()), list()}

  # This is the main entry point to the application
  def main(argv) do
    argv
    |> Args.parse_args()
    |> process()
  end

  # Starts the application processing based on the parsing of the arguments
  defp process({:ok, :help}) do
    output_usage_info()

    System.halt(0)
  end

  defp process({:error, messages}) do
    Enum.each(messages, &IO.puts/1)

    IO.puts("")

    output_usage_info()
  end

  defp process({:ok, options}) do
    integer_range = options.lower_bound..options.upper_bound

    # Create the random integer stream
    random_stream = IntGen.random_integer_stream(integer_range)

    # Create the integer file using the random integer stream
    IntGen.create_integer_file(options.output_file, options.count, random_stream)
  end

  # Prints usage information
  defp output_usage_info() do
    IO.puts("""
    usage: int_gen --count <count> --lower-bound <lower bound> --upper-bound <upper bound> <file>

    example: int_gen --count 100 --lower-bound -100 --upper-bound 100 "random_integers.txt"
    """)
  end
end
