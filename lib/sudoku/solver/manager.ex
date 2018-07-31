defmodule Sudoku.Solver.Manager do
  use GenServer
  alias Sudoku.Puzzle.Verify
  alias Sudoku.Solver.Worker

  # Print a dot every 100th worker we launch.
  @status_every 100

  # Launch up to 10k workers at once.
  @max_workers 10000

  defmodule State do
    @enforce_keys [:supervisor]
    defstruct(
      supervisor: nil,
      waiting: [],
      queue: :queue.new(),
      solutions: [],
      launched: 0,
      max_active: 0
    )
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def queue(pid, puzzle) do
    GenServer.cast(pid, {:queue, puzzle})
  end

  def solved(pid, puzzle) do
    Verify.verify(puzzle)
    GenServer.cast(pid, {:solved, puzzle})
  end

  def await(pid) do
    {_solutions, _max_active} = GenServer.call(pid, :wait)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  @impl true
  def init(nil) do
    {:ok, supervisor} =
      DynamicSupervisor.start_link(
        strategy: :one_for_one,
        max_children: @max_workers
      )

    {:ok, %State{supervisor: supervisor}}
  end

  defp workers_running?(supervisor) do
    count_active_workers(supervisor) > 0
  end

  defp count_active_workers(supervisor) do
    DynamicSupervisor.count_children(supervisor).active
  end

  @impl true
  def handle_cast({:queue, puzzle}, state) do
    queue = :queue.in(puzzle, state.queue)
    state = %State{state | queue: queue}
    state = launch_queued(state)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:solved, puzzle}, state) do
    state = %State{state | solutions: [puzzle | state.solutions]}
    {:noreply, state}
  end

  @impl true
  def handle_call(:wait, from, state) do
    if workers_running?(state.supervisor) do
      {:noreply, %State{state | waiting: [from | state.waiting]}}
    else
      {:reply, wait_reply(state)}
    end
  end

  defp wait_reply(state) do
    {state.solutions,
     [
       launched: state.launched,
       max_active: state.max_active
     ]}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    state = launch_queued(state)

    if workers_running?(state.supervisor) do
      {:noreply, state}
    else
      Enum.each(state.waiting, fn from ->
        GenServer.reply(from, wait_reply(state))
      end)

      {:noreply, %State{state | waiting: []}}
    end
  end

  defp launch_queued(state) do
    {item, new_queue} = :queue.out(state.queue)

    case item do
      {:value, puzzle} ->
        case launch_puzzle(puzzle, state) do
          {:ok, _pid} ->
            state = %State{
              state
              | queue: new_queue,
                max_active: max(state.max_active, count_active_workers(state.supervisor)),
                launched: state.launched + 1
            }

            if rem(state.launched, @status_every) == 0 do
              IO.write(".")
            end

            launch_queued(state)

          {:error, :max_children} ->
            state
        end

      :empty ->
        state
    end
  end

  defp launch_puzzle(puzzle, state) do
    spec = Worker.child_spec(puzzle, self())

    case DynamicSupervisor.start_child(state.supervisor, spec) do
      {:ok, pid} ->
        Process.monitor(pid)
        {:ok, pid}

      {:error, :max_children} ->
        {:error, :max_children}
    end
  end
end
