defmodule Mix.Tasks.Sudoku.Benchmark do
  use Mix.Task

  @shortdoc "Benchmark the solver against one or more puzzle files"

  @switches [
    warmup: :float,
    time: :float,
    max_children: :string,
    html: :string
  ]

  @defaults [
    warmup: 2.0,
    time: 10.0,
    max_children: "10,100,1000,10000",
    html: nil
  ]

  def run(args) do
    {opts, files} = OptionParser.parse!(args, strict: @switches)
    files = Enum.uniq(files)
    ruby = which_ruby()

    IO.puts("")
    IO.puts("Git commit: #{git_head()}")
    IO.puts("Ruby version: #{ruby_version(ruby)}")
    IO.puts("")

    opts =
      Keyword.merge(@defaults, opts)
      |> Keyword.put(:inputs, Enum.map(files, &make_input(ruby, &1)))

    {max_children, opts} = Keyword.pop(opts, :max_children)
    max_children = String.split(max_children, ",") |> Enum.map(&String.to_integer/1)

    opts = add_formatters(opts)

    Benchee.run(
      [
        {"ruby", fn {_, ruby} -> ruby_solve(ruby) end},
        {"inline", fn {puzzle, _} -> Sudoku.Solver.solve_inline(puzzle) end},
        Enum.map(max_children, fn max ->
          {"managed (#{max})",
           fn {puzzle, _} -> Sudoku.Solver.solve(puzzle, max_children: max) end}
        end)
      ]
      |> List.flatten(),
      opts
    )
  end

  defp make_input(ruby, file) do
    puzzle = Sudoku.Puzzle.read(file)
    ruby = RubySolver.launch(ruby, file)
    {file, {puzzle, ruby}}
  end

  defp ruby_solve(ruby) do
    RubySolver.run(ruby)
  end

  defp which_ruby() do
    {ruby, 0} = System.cmd("which", ["ruby"])
    String.trim(ruby)
  end

  defp ruby_version(ruby) do
    {output, 0} = System.cmd(ruby, ["--version"])
    String.trim(output)
  end

  defp git_head() do
    {output, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    String.trim(output)
  end

  defp add_formatters(opts) do
    case Keyword.pop(opts, :html) do
      {nil, opts} ->
        opts

      {file, opts} ->
        opts
        |> Keyword.put(:formatters, [Benchee.Formatters.HTML, Benchee.Formatters.Console])
        |> Keyword.put(:formatter_options, html: [file: file])
    end
  end
end

defmodule RubySolver do
  use GenServer

  defmodule State do
    @enforce_keys [:port]
    defstruct(
      port: nil,
      expect_id: nil,
      reply_to: nil
    )
  end

  def launch(ruby, file) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {ruby, file})
    :pong = GenServer.call(pid, :ping)
    pid
  end

  def run(pid) do
    GenServer.call(pid, :run, 30_000)
  end

  @impl true
  def init({ruby, file}) do
    port =
      Port.open(
        {:spawn_executable, ruby},
        [args: ["other/sudoku.rb", "--benchmark", file]] ++ [:binary]
      )

    {:ok, %State{port: port}}
  end

  @impl true
  def handle_call(:ping, _from, state), do: {:reply, :pong, state}

  @impl true
  def handle_call(:run, from, state) do
    if is_nil(state.expect_id) do
      id = random_id()
      Port.command(state.port, "#{id}\n")
      {:noreply, %State{state | expect_id: id, reply_to: from}}
    else
      raise "Already waiting for #{inspect(state.expect_id)}"
    end
  end

  @impl true
  def handle_info({_port, {:data, data}}, state) do
    id = String.trim(data)

    if id == state.expect_id do
      GenServer.reply(state.reply_to, :ok)
      {:noreply, %State{state | expect_id: nil, reply_to: nil}}
    else
      raise "Expected id #{inspect(state.expect_id)}, got #{inspect(id)}"
    end
  end

  @alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @digits "0123456789"
  @letters [
             String.upcase(@alphabet),
             String.downcase(@alphabet),
             @digits
           ]
           |> Enum.join()
           |> String.to_charlist()

  defp random_id() do
    Enum.map(1..8, fn _ -> Enum.random(@letters) end)
    |> String.Chars.to_string()
  end
end
