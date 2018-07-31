defmodule Mix.Tasks.Solve do
  use Mix.Task

  @shortdoc "Solve Sudoku puzzle files"

  def run(files) do
    Enum.each(files, fn file ->
      IO.write("Solving: #{file} ")

      {solutions, stats} = Sudoku.Puzzle.read(file) |> Sudoku.Solver.solve()

      IO.puts("\nGot #{Enum.count(solutions)} solution(s):")

      Enum.each(solutions, fn solution ->
        IO.puts("")
        Sudoku.Puzzle.to_string(solution) |> IO.puts()
      end)

      IO.puts("\nStatistics:")

      Enum.each(stats, fn {name, value} ->
        IO.puts("    #{name}: #{value}")
      end)

      IO.puts("")
    end)
  end
end
