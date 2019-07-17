defmodule IntSortTest do
  use ExUnit.Case
  doctest IntSort

  describe "gen_file_name -" do
    test "Create a gen file name" do
      file_name = IntSort.gen_file_name(3, 7)

      assert file_name == "gen3-7.txt"
    end
end
