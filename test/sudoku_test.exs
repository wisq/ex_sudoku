defmodule SudokuTest do
  use ExUnit.Case
  doctest Sudoku

  test "greets the world" do
    assert Sudoku.hello() == :world
  end
end
