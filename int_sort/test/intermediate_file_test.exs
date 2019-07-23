defmodule IntSort.IntermediateFileTest do
  use ExUnit.Case, async: true

  alias IntSort.IntermediateFile
  # alias LargeSort.Shared.TestStream
  # alias LargeSort.Shared.TestData
  # alias IntSort.Test

  import Mox

  doctest IntermediateFile

  describe "intermediate_file_stream -" do
    test "Create an intermediate file stream" do
      test_intermediate_file_stream(1, 1)
      test_intermediate_file_stream(10, 12)
      test_intermediate_file_stream(4, 2)
    end

    @test_output_dir "output"

    @spec test_intermediate_file_stream(non_neg_integer(), non_neg_integer()) :: :ok
    defp test_intermediate_file_stream(gen, file_num) do
      # Create any mocks that need to be created
      intermediate_file_stream_mocks()

      # Call intermediate_file_stream and get the stream
      intermediate_stream = IntermediateFile.intermediate_file_stream(gen, file_num,
        &intermediate_file_name/2, @test_output_dir)

      # Verify the results
      verify_intermediate_stream_results(intermediate_stream, gen, file_num)
    end

    # Mocks any modules that need to be mocked
    @spec intermediate_file_stream_mocks() :: :ok
    defp intermediate_file_stream_mocks() do
      # Mock IntegerFileMock so that returns a dummy stream when creating
      # an integer file stream. This dummy stream will contain the path
      # passed to the function so that we can later read it and verify
      # that the correct parameters were passed
      IntSort.IntegerFileMock
      |> expect(
        :integer_file_stream,
        fn path ->
          [path]
        end
      )
    end

    # Creates a test intermediate file name
    @spec intermediate_file_name(non_neg_integer(), non_neg_integer()) :: String.t()
    defp intermediate_file_name(gen, file_num) do
      "gen#{gen}file#{file_num}.txt"
    end

    # Verifies the results of the intermediate stream test
    @spec verify_intermediate_stream_results(Enum.t(), list(integer()), non_neg_integer()) :: :ok
    defp verify_intermediate_stream_results(intermediate_stream, gen, file_num) do
      # Get the contents of the intermediate stream
      [file_path] = Enum.to_list(intermediate_stream)

      # Get the expected file path
      expected_file_path = Path.join(@test_output_dir, intermediate_file_name(gen, file_num))

      # Ensure that the expected file path matches the actual file path
      assert file_path == expected_file_path

      :ok
    end
  end
end
