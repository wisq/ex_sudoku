defmodule Mix.Tasks.Sudoku.Solve do
  use Mix.Task

  @shortdoc "Solve Sudoku puzzle files"

  @switches [
    inline: :boolean
  ]

  def run(args) do
    {opts, files} = OptionParser.parse!(args, strict: @switches)

    Enum.each(files, fn file ->
      IO.write("Solving: #{file} ")
      puzzle = Sudoku.Puzzle.read(file)

      {micros, {solutions, stats}} =
        :timer.tc(fn ->
          if opts[:inline] do
            Sudoku.Solver.solve_inline(puzzle)
          else
            Sudoku.Solver.solve(puzzle)
          end
        end)

      IO.puts("\nGot #{Enum.count(solutions)} solution(s) in #{time_to_string(micros)}:")

      Enum.each(solutions, fn solution ->
        IO.puts("")
        Sudoku.Puzzle.to_string(solution) |> IO.puts()
      end)

      unless Enum.empty?(stats) do
        IO.puts("\nStatistics:")

        Enum.each(stats, fn {name, value} ->
          IO.puts("    #{name}: #{value}")
        end)
      end

      IO.puts("")
    end)
  end

  defp time_to_string(t) when t < 1_000, do: "#{t} µs"

  defp time_to_string(t) when t < 1_000_000 do
    ms = :erlang.float_to_binary(t / 1000, decimals: 2)
    "#{ms} ms"
  end

  defp time_to_string(t) do
    s = :erlang.float_to_binary(t / 1_000_000, decimals: 2)
    "#{s} s"
  end
end
