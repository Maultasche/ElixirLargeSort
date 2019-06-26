defmodule IntGen.CLI.Args.Test do
  use ExUnit.Case, async: true
  doctest IntGen.CLI.Args

  alias IntGen.CLI.Args
  alias IntGen.CLI.Options

  describe "parse_args -" do
    @test_file "dir/file.txt"

    test "Parsing args with full set of valid arguments" do
      test_args = ["--count", "10", "--lower-bound", "1", "--upper-bound", "100",
        @test_file]

      expected_options = Options.new(10, 1, 100, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with no arguments" do
      test_args = []

      test_with_args_error(test_args, 4)
    end

    test "Parsing args with help argument" do
      test_args = ["--help"]

      test_with_args_help(test_args)
    end

    test "Parsing args with help argument and additional arguments" do
      test_args = ["--count", "10", "--lower-bound", "1", "--upper-bound", "100",
        "--help", @test_file]

        test_with_args_help(test_args)
    end

    test "Parsing args with missing count argument" do
      test_args = ["--lower-bound", "1", "--upper-bound", "100",
        @test_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args with a negative count" do
      test_args = ["--count", "-10", "--lower-bound", "1", "--upper-bound", "100",
        @test_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args with a zero count" do
      test_args = ["--count", "0", "--lower-bound", "1", "--upper-bound", "100",
        @test_file]

      expected_options = Options.new(0, 1, 100, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with negative lower and upper bounds" do
      test_args = ["--count", "10", "--lower-bound", "-300", "--upper-bound", "-100",
        @test_file]

      expected_options = Options.new(10, -300, -100, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with positive lower and upper bounds" do
      test_args = ["--count", "10", "--lower-bound", "1000", "--upper-bound", "10000",
        @test_file]

      expected_options = Options.new(10, 1000, 10000, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args with zero lower and upper bounds" do
      test_args = ["--count", "10", "--lower-bound", "0", "--upper-bound", "0",
        @test_file]

      expected_options = Options.new(10, 0, 0, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args where upper bound is the same as the lower bound" do
      test_args = ["--count", "10", "--lower-bound", "10", "--upper-bound", "10",
        @test_file]

      expected_options = Options.new(10, 10, 10, @test_file)

      test_with_args_success(test_args, expected_options)
    end

    test "Parsing args where upper bound is the less than the lower bound" do
      test_args = ["--count", "10", "--lower-bound", "10", "--upper-bound", "-10",
        @test_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args where the lower bound is missing" do
      test_args = ["--count", "10", "--upper-bound", "-10",
        @test_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args where the upper bound is missing" do
      test_args = ["--count", "10", "--lower-bound", "10",
        @test_file]

      test_with_args_error(test_args, 1)
    end

    test "Parsing args where the output file is missing" do
      test_args = ["--count", "10", "--lower-bound", "-10", "--upper-bound", "10"]

      test_with_args_error(test_args, 1)
    end
  end

  #Tests parse_args when success is expected
  def test_with_args_success(args, expected_options) do
    Args.parse_args(args)
    {:ok, result} = Args.parse_args(args)

    assert result == expected_options
  end

  #Tests parse_args when a help response is expected
  def test_with_args_help(args) do
    {:ok, result} = Args.parse_args(args)

    assert result == :help
  end

  #Test parse_args when an error is expected
  def test_with_args_error(args, num_errors) do
    {:error, error_messages} = Args.parse_args(args)

    assert length(error_messages) == num_errors
  end
end
