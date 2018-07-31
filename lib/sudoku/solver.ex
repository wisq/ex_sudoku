defmodule Sudoku.Solver do
  alias Sudoku.Puzzle.Verify
  alias Sudoku.Solver.Manager

  def solve(puzzle) do
    {:ok, manager} = Manager.start_link()
    Manager.queue(manager, puzzle)
    result = Manager.await(manager)
    Manager.stop(manager)

    result
  end
end
