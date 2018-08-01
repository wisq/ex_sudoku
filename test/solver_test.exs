defmodule Sudoku.SolverTest do
  use ExUnit.Case
  alias Sudoku.Puzzle
  alias Sudoku.Solver

  test "easy" do
    assert {[solution], stats} = Puzzle.read("data/easy.txt") |> Solver.solve()
    assert stats.launched == 1
    assert stats.max_active == 1

    assert solution == [
             [5, 2, 8, 6, 4, 7, 1, 9, 3],
             [9, 4, 1, 8, 3, 2, 7, 5, 6],
             [6, 3, 7, 5, 9, 1, 2, 8, 4],
             [2, 8, 6, 4, 5, 9, 3, 1, 7],
             [7, 5, 3, 2, 1, 8, 6, 4, 9],
             [4, 1, 9, 7, 6, 3, 5, 2, 8],
             [8, 7, 5, 9, 2, 6, 4, 3, 1],
             [3, 6, 4, 1, 8, 5, 9, 7, 2],
             [1, 9, 2, 3, 7, 4, 8, 6, 5]
           ]
  end

  test "puz1" do
    assert {[solution], stats} = Puzzle.read("data/puz1.txt") |> Solver.solve()
    assert stats.launched == 2
    assert stats.max_active == 1 || stats.max_active == 2

    assert solution == [
             [7, 9, 6, 8, 5, 4, 3, 2, 1],
             [2, 4, 3, 1, 7, 6, 9, 8, 5],
             [8, 5, 1, 2, 3, 9, 4, 7, 6],
             [1, 3, 7, 9, 6, 5, 8, 4, 2],
             [9, 2, 5, 4, 1, 8, 7, 6, 3],
             [4, 6, 8, 7, 2, 3, 5, 1, 9],
             [6, 1, 4, 5, 9, 7, 2, 3, 8],
             [5, 8, 2, 3, 4, 1, 6, 9, 7],
             [3, 7, 9, 6, 8, 2, 1, 5, 4]
           ]
  end

  test "puz2" do
    assert {[solution], stats} = Puzzle.read("data/puz2.txt") |> Solver.solve()
    assert stats.launched == 32
    assert stats.max_active > 1

    assert solution == [
             [7, 9, 2, 8, 3, 5, 4, 6, 1],
             [3, 5, 4, 9, 1, 6, 2, 8, 7],
             [8, 1, 6, 2, 7, 4, 3, 5, 9],
             [4, 8, 7, 5, 2, 9, 6, 1, 3],
             [6, 3, 9, 4, 8, 1, 7, 2, 5],
             [1, 2, 5, 7, 6, 3, 9, 4, 8],
             [9, 4, 1, 6, 5, 7, 8, 3, 2],
             [2, 7, 3, 1, 4, 8, 5, 9, 6],
             [5, 6, 8, 3, 9, 2, 1, 7, 4]
           ]
  end

  test "puz3" do
    assert {[solution], stats} = Puzzle.read("data/puz3.txt") |> Solver.solve()
    assert stats.launched == 4
    assert stats.max_active > 1

    assert solution == [
             [5, 1, 9, 7, 4, 8, 6, 3, 2],
             [7, 8, 3, 6, 5, 2, 4, 1, 9],
             [4, 2, 6, 1, 3, 9, 8, 7, 5],
             [3, 5, 7, 9, 8, 6, 2, 4, 1],
             [2, 6, 4, 3, 1, 7, 5, 9, 8],
             [1, 9, 8, 5, 2, 4, 3, 6, 7],
             [9, 7, 5, 8, 6, 3, 1, 2, 4],
             [8, 3, 2, 4, 9, 1, 7, 5, 6],
             [6, 4, 1, 2, 7, 5, 9, 8, 3]
           ]
  end

  test "puz4" do
    assert {[solution], stats} = Puzzle.read("data/puz4.txt") |> Solver.solve()
    assert stats.launched == 926
    assert stats.max_active > 30

    assert solution == [
             [7, 8, 2, 4, 5, 3, 6, 1, 9],
             [4, 6, 5, 1, 9, 7, 8, 2, 3],
             [3, 1, 9, 6, 8, 2, 7, 5, 4],
             [5, 9, 3, 8, 4, 1, 2, 6, 7],
             [1, 2, 7, 3, 6, 9, 4, 8, 5],
             [8, 4, 6, 7, 2, 5, 9, 3, 1],
             [6, 7, 1, 9, 3, 8, 5, 4, 2],
             [2, 3, 8, 5, 7, 4, 1, 9, 6],
             [9, 5, 4, 2, 1, 6, 3, 7, 8]
           ]
  end

  test "puz5" do
    assert {[solution], stats} = Puzzle.read("data/puz5.txt") |> Solver.solve()
    assert stats.launched == 736
    assert stats.max_active > 50

    assert solution == [
             [3, 1, 7, 6, 8, 4, 9, 2, 5],
             [9, 8, 2, 5, 7, 3, 6, 4, 1],
             [6, 5, 4, 1, 9, 2, 7, 8, 3],
             [8, 4, 6, 9, 2, 5, 3, 1, 7],
             [5, 9, 3, 7, 1, 8, 2, 6, 4],
             [7, 2, 1, 4, 3, 6, 8, 5, 9],
             [4, 7, 5, 2, 6, 9, 1, 3, 8],
             [2, 3, 9, 8, 5, 1, 4, 7, 6],
             [1, 6, 8, 3, 4, 7, 5, 9, 2]
           ]
  end

  test "hard" do
    assert {[solution], stats} = Puzzle.read("data/hard.txt") |> Solver.solve()
    assert stats.launched == 1800
    assert stats.max_active > 100

    assert solution == [
             [8, 1, 2, 7, 5, 3, 6, 4, 9],
             [9, 4, 3, 6, 8, 2, 1, 7, 5],
             [6, 7, 5, 4, 9, 1, 2, 8, 3],
             [1, 5, 4, 2, 3, 7, 8, 9, 6],
             [3, 6, 9, 8, 4, 5, 7, 2, 1],
             [2, 8, 7, 1, 6, 9, 5, 3, 4],
             [5, 2, 1, 9, 7, 4, 3, 6, 8],
             [4, 3, 8, 5, 2, 6, 9, 1, 7],
             [7, 9, 6, 3, 1, 8, 4, 5, 2]
           ]
  end

  test "hard with max_children: 20" do
    assert {[solution], stats} = Puzzle.read("data/hard.txt") |> Solver.solve(max_children: 20)
    assert stats.launched == 1800
    assert stats.max_active == 20

    assert solution == [
             [8, 1, 2, 7, 5, 3, 6, 4, 9],
             [9, 4, 3, 6, 8, 2, 1, 7, 5],
             [6, 7, 5, 4, 9, 1, 2, 8, 3],
             [1, 5, 4, 2, 3, 7, 8, 9, 6],
             [3, 6, 9, 8, 4, 5, 7, 2, 1],
             [2, 8, 7, 1, 6, 9, 5, 3, 4],
             [5, 2, 1, 9, 7, 4, 3, 6, 8],
             [4, 3, 8, 5, 2, 6, 9, 1, 7],
             [7, 9, 6, 3, 1, 8, 4, 5, 2]
           ]
  end
end
