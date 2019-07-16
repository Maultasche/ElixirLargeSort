defmodule IntSort.CLI.Args.Test do
  use ExUnit.Case, async: true
  doctest IntSort.CLI.Args

  alias IntSort.CLI.Args
  alias IntSort.CLI.Options

  describe "parse_args -" do
    @test_output_file "output/output.txt"
    @test_input_file "data/input.txt"

    test "Parsing args with full set of valid arguments" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "100", "--keep-intermediate", @test_output_file]

      expected_options = Options.new(@test_input_file, @test_output_file, 100, true)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with no arguments" do
      test_args = []

      test_with_args_error(test_args, 3)
    end

    test "Parsing args with help argument" do
      test_args = ["--help"]

      test_with_args_help(test_args)
    end

    test "Parsing args with help argument and additional arguments" do
      test_args = [
        "--input-file",
        @test_input_file,
        "--chunk-size",
        "100",
        "--keep-immediate",
        "--help",
        @test_output_file
      ]

      test_with_args_help(test_args)
    end

    test "Parsing args with missing input file argument" do
      test_args = ["--chunk-size", "100", "--keep-intermediate", @test_output_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args with a chunk size of 1" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "1", "--keep-intermediate", @test_output_file]

      expected_options = Options.new(@test_input_file, @test_output_file, 1, true)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with a negative chunk size" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "-1", "--keep-intermediate", @test_output_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args with a zero chunk size" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "0", "--keep-intermediate", @test_output_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args with missing keep intermediate option" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "100", @test_output_file]

      expected_options = Options.new(@test_input_file, @test_output_file, 100, false)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args where the output file is missing" do
      test_args = ["--input-file", @test_input_file, "--chunk-size", "100"]

      test_with_args_error(test_args, 1)
    end
  end

  # Tests parse_args when success is expected
  def test_with_args_success(args, expected_options) do
    Args.parse_args(args)
    {:ok, result} = Args.parse_args(args)

    assert result == expected_options
  end

  # Tests parse_args when a help response is expected
  def test_with_args_help(args) do
    {:ok, result} = Args.parse_args(args)

    assert result == :help
  end

  # Test parse_args when an error is expected
  def test_with_args_error(args, num_errors) do
    {:error, error_messages} = Args.parse_args(args)

    assert length(error_messages) == num_errors
  end
end
