defmodule ConcurrentCount.PutCache do
  use GenServer
  # GenServer state is
  # {numHeld, []}

  def start_link(_opts \\ []) do
    state = {0, []}
    GenServer.start_link(__MODULE__, state, name: PutCache)
  end

  # GenServer Callbacks
  def handle_call({:put, msg}, _from, {size, list}) when size < 50 do
    {:reply, {size, list}, {size + 1, list ++ [msg]}}
  end
  def handle_call({:put, msg}, _from, {size, [_first|rest]}) do
    new_list = rest ++ [msg]
    {:reply, {size, new_list}, {size, new_list}}
  end

  def handle_call({:inspect}, _from, {size, list}) do
    {:reply, {size, list}, {size, list}}
  end

  def init(args) do
    # Hard match on expected args, state is empty.
    {0, []} = args
    {:ok, args}
  end
end
