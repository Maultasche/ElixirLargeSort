defmodule IntGen.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  import IntGen.CLI.Options

  @type parsed_args() :: {keyword(), list(String.t()), list()}

  # This is the main entry point to the application
  def main(argv) do
    argv
    |> parse_args()
    |> process()
  end

  # Parses the command line arguments
  #
  # Valid switches are:
  #   - --help: displays help information
  #   - --count: number of integers to be generated
  #   - --lower-bound: the lower bound (inclusive) of the integers to be generated
  #   - --upper-bound: the upper bound (inclusive) of the integers to be generated
  #
  # The last argument is a standalone argument containing the path of the file the
  # generated integers are to be written to
  #
  # Parameters
  #
  # - argv: a string containing the command line arguments
  #
  # Returns
  #
  # A tuple containing the parsed parameters or `:help` if help was requested
  def parse_args(argv) do
    OptionParser.parse(argv,
      switches: [help: :boolean, count: :integer, lower_bound: :integer, upper_bound: :integer],
      aliases: [h: :help, c: :count, l: :lower_bound, u: :upper_bound]
    )
    |> args_to_options()
    |> process()
  end

  @spec args_to_options(parsed_args()) :: Options.t() | {:error, list(String.t())} | :help
  defp args_to_options({parsed_args, additional_args, _}) do
    :help
  end

  defp process(:help) do
    IO.puts("""
    usage: int_gen --count <count> --lower_bound <lower bound> --upper_bound <upper bound> <file>

    example: int_gen --count 100 --lower_bound -100 --upper_bound 100 "random_integers.txt"
    """)

    System.halt(0)
  end

  defp process({:error, messages}) do
  end

  defp process(options) do
    output_options(options)
  end

  defp validate_args({parsed_args, additional_args, _}) do
  end

  @spec contains_help_switch(keyword()) :: boolean()
  defp contains_help_switch(parsed_args) do
    Keyword.has_key?(parsed_args, :help)
  end

  # This is a helpful debugging function to print out the options when you need to verify
  # what they actually are
  defp output_options(options) do
    IO.puts(inspect(options))
  end
end
