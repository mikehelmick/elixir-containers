defmodule ConcurrentCount.Cpucount do
  use GenServer
  # GenServer state is
  #  {curRunning, requests, min, max, totalMs}
  # Assumes a Max of 10 concurrent mining requets.

  import ConcurrentCount.Environment

  def start_link(_opts \\ []) do
    state = {0, 0, 0, 0, 0, get_int_env("miners", 10)}
    GenServer.start_link(__MODULE__, state, name: Miner)
  end

  # GenServer Callbacks
  def handle_call({:maybe_mine}, _from, {curRunning, requests, min, max, totalMs, 0})  do
    IO.puts("maybemine - disabled")
    {:reply, {:error, 0}, {curRunning, requests, min, max, totalMs, 0}}
  end
  def handle_call({:maybe_mine}, _from, {curRunning, requests, min, max, totalMs, miners}) when curRunning < miners do
    IO.puts("maybemine - true")
    {:reply, {:ok, curRunning}, {curRunning + 1, requests, min, max, totalMs, miners}}
  end
  def handle_call({:maybe_mine}, _from, {curRunning, requests, min, max, totalMs, miners}) when curRunning >= miners do
    IO.puts("maybemine - false")
    {:reply, {:error, curRunning}, {curRunning, requests, min, max, totalMs, miners}}
  end

  def handle_call({:done_mining, time}, _from, {curRunning, 0, 0, 0, 0, miners}) when curRunning > 0 do
    # special case for first one finihsed
    {:reply, :ok, {curRunning - 1, 1, time, time, time, miners}}
  end
  def handle_call({:done_mining, time}, _from, {curRunning, requests, min, max, totalMs, miners}) when curRunning > 0 do
    {:reply, :ok, {curRunning - 1, requests + 1, min(min, time), max(max, time), totalMs + time, miners}}
  end

  def handle_call({:inspect}, _from, state) do
    {:reply, state, state}
  end

  def init(args) do
    # Hard match on expected args.
    {0, 0, 0, 0, 0, _} = args
    {:ok, args}
  end

end
