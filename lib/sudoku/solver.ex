defmodule Sudoku.Solver do
  alias Sudoku.Solver.Manager

  def solve(puzzle, opts \\ []) do
    {:ok, manager} = Manager.start_link(opts)
    Manager.queue(manager, puzzle)
    result = Manager.await(manager)
    Manager.stop(manager)

    result
  end
end
