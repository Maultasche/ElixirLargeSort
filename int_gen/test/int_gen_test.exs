defmodule IntGenTest do
  use ExUnit.Case
  doctest IntGen

  @num_stream_elements 1000

  describe "Testing the random integer stream" do
    test "Generates integers" do
      random_stream = IntGen.random_integer_stream(1, 100)

      random_stream
      |> Enum.take(@num_stream_elements)
      |> test_integers()
    end

    test "Testing range with only positive numbers" do
      test_range(1, 100)
    end

    test "Testing range with positive and negative numbers" do
      test_range(-10, 10)
    end

    test "Testing range with negative numbers" do
      test_range(-87, -12)
    end

    test "Testing range that starts with 0" do
      test_range(0, 23)
    end

    test "Testing range that ends with 0" do
      test_range(-145, 0)
    end

    test "Testing range of size 2" do
      test_range(4, 5)
    end

    test "Testing range of size 1" do
      test_range(12, 12)
    end

    test "Testing range 0..0" do
      test_range(0, 0)
    end

    test "Testing descending range" do
      test_range(10, -2)
    end

    test "Testing large range" do
      test_range(-1_000_000_000, 1_000_000_000)
    end
  end

  defp test_integers(enumerable) do
    Enum.each(enumerable, fn element -> assert is_integer(element) end)
  end

  defp test_range(min_value, max_value) do
    random_stream = IntGen.random_integer_stream(min_value, max_value)

    expected_range = min_value..max_value

    random_stream
    |> Enum.take(@num_stream_elements)
    |> Enum.each(fn integer -> integer in expected_range end)
  end
end
