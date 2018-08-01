defmodule Sudoku.PuzzleTest do
  use ExUnit.Case
  alias Sudoku.Puzzle

  @easy [
    [nil, 2, 8, 6, 4, 7, 1, 9, 3],
    [9, 4, 1, 8, nil, nil, nil, 5, 6],
    [6, nil, 7, 5, 9, 1, 2, 8, nil],
    [2, 8, nil, nil, nil, 9, 3, 1, 7],
    [7, 5, 3, 2, 1, nil, 6, nil, 9],
    [nil, nil, nil, nil, 6, nil, nil, 2, nil],
    [8, nil, 5, nil, nil, 6, nil, 3, nil],
    [3, 6, 4, 1, 8, 5, 9, 7, nil],
    [1, nil, nil, nil, 7, nil, 8, 6, nil]
  ]

  @puz1 [
    [7, 9, nil, nil, nil, nil, 3, nil, nil],
    [nil, nil, nil, nil, nil, 6, 9, nil, nil],
    [8, nil, nil, nil, 3, nil, nil, 7, 6],
    [nil, nil, nil, nil, nil, 5, nil, nil, 2],
    [nil, nil, 5, 4, 1, 8, 7, nil, nil],
    [4, nil, nil, 7, nil, nil, nil, nil, nil],
    [6, 1, nil, nil, 9, nil, nil, nil, 8],
    [nil, nil, 2, 3, nil, nil, nil, nil, nil],
    [nil, nil, 9, nil, nil, nil, nil, 5, 4]
  ]

  test "parses Sudoku puzzles from disk" do
    puzzle1 = Puzzle.read("data/puz1.txt")
    assert puzzle1 == @puz1

    puzzle2 = Puzzle.read("data/easy.txt")
    assert puzzle2 == @easy
  end

  test "get_row/2" do
    assert Puzzle.get_row(@easy, 0) == [nil, 2, 8, 6, 4, 7, 1, 9, 3]
    assert Puzzle.get_row(@puz1, 5) == [4, nil, nil, 7, nil, nil, nil, nil, nil]
  end

  test "get_column/2" do
    assert Puzzle.get_column(@easy, 0) == [nil, 9, 6, 2, 7, nil, 8, 3, 1]
    assert Puzzle.get_column(@puz1, 5) == [nil, 6, nil, 5, 8, nil, nil, nil, nil]
  end

  test "get_square/2" do
    assert Puzzle.get_square(@easy, 0) == [nil, 2, 8, 9, 4, 1, 6, nil, 7]
    assert Puzzle.get_square(@puz1, 5) == [nil, nil, 2, 7, nil, nil, nil, nil, nil]
  end

  test "get_square/3" do
    assert Puzzle.get_square(@easy, 1, 1) == [nil, 2, 8, 9, 4, 1, 6, nil, 7]
    assert Puzzle.get_square(@puz1, 3, 6) == [nil, nil, 2, 7, nil, nil, nil, nil, nil]
  end

  test "get_value/3" do
    assert Puzzle.get_value(@easy, 0, 1) == 2
    assert Puzzle.get_value(@puz1, 5, 3) == 7
  end

  test "square_number/2" do
    assert Puzzle.square_number(1, 1) == 0
    assert Puzzle.square_number(2, 3) == 1
    assert Puzzle.square_number(5, 8) == 5
  end

  test "put_value/4" do
    puz1 = @puz1
    assert Puzzle.get_row(puz1, 5) == [4, nil, nil, 7, nil, nil, nil, nil, nil]
    assert Puzzle.get_column(puz1, 5) == [nil, 6, nil, 5, 8, nil, nil, nil, nil]

    puz1 =
      puz1
      # Alter row 5:
      |> Puzzle.put_value(5, 8, 1)
      |> Puzzle.put_value(5, 7, 2)
      |> Puzzle.put_value(5, 6, 3)
      |> Puzzle.put_value(5, 5, 4)
      |> Puzzle.put_value(5, 4, 5)
      |> Puzzle.put_value(5, 3, 6)
      |> Puzzle.put_value(5, 2, 7)
      |> Puzzle.put_value(5, 1, 8)
      |> Puzzle.put_value(5, 0, 9)
      # Alter column 5:
      |> Puzzle.put_value(8, 5, 1)
      |> Puzzle.put_value(7, 5, 2)
      |> Puzzle.put_value(6, 5, 3)
      |> Puzzle.put_value(5, 5, 4)
      |> Puzzle.put_value(4, 5, 5)
      |> Puzzle.put_value(3, 5, 6)
      |> Puzzle.put_value(2, 5, 7)
      |> Puzzle.put_value(1, 5, 8)
      |> Puzzle.put_value(0, 5, 9)

    assert Puzzle.get_row(puz1, 5) == [9, 8, 7, 6, 5, 4, 3, 2, 1]
    assert Puzzle.get_column(puz1, 5) == [9, 8, 7, 6, 5, 4, 3, 2, 1]
  end

  test "to_string/1" do
    assert Puzzle.to_string(@easy) ==
             """
             _28 647 193
             941 8__ _56
             6_7 591 28_

             28_ __9 317
             753 21_ 6_9
             ___ _6_ _2_

             8_5 __6 _3_
             364 185 97_
             1__ _7_ 86_
             """
             |> String.trim()

    assert Puzzle.to_string(@puz1) == File.read!("data/puz1.txt") |> String.trim()
  end
end
