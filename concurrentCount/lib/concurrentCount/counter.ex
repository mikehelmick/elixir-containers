defmodule ConcurrentCount.Counter do
  use GenServer
  # GenServer state is
  # {numOpen, [<pids>], peak}

  def start_link(_opts \\ []) do
    state = {0, 0, 0, 0, UUID.uuid4()}
    GenServer.start_link(__MODULE__, state, name: Counter)
  end

  # GenServer Callbacks
  def handle_call({:open}, _from, {size, peak, started, finished, node}) when size + 1 > peak do
    {:reply, size + 1, {size + 1, size + 1, started + 1, finished, node}}
  end
  def handle_call({:open}, _from, {size, peak, started, finished, node}) do
    {:reply, size, {size + 1, peak, started + 1, finished, node}}
  end

  def handle_call({:close}, _from, {0, peak, started, finished, node}) do
    new_state = {0, peak, started, finished, node}
    {:reply, new_state, new_state}
  end
  def handle_call({:close}, _from, {size, peak, started, finished, node}) do
    new_state = {size - 1, peak, started, finished + 1, node}
    {:reply, new_state, new_state}
  end

  def handle_call({:inspect}, _from, state) do
    {:reply, state, state}
  end

  def init(args) do
    # Hard match on expected args.
    {0, 0, 0, 0, _uuid} = args
    {:ok, args}
  end
end
