defmodule ConcurrentCountWeb.PageController do
  use ConcurrentCountWeb, :controller

  defp get_delay() do
    ConcurrentCount.Environment.get_int_env("DELAY", 1000)
  end

  def average(_, 0) do
    "0"
  end
  def average(mineTime, mineCount) do
    :erlang.float_to_binary(mineTime / mineCount, decimals: 2)
  end

  defp maybe_spawn_miner(true) do
    spawn fn() -> ConcurrentCount.Bitcoin.mine() end
    IO.puts("Spawned miner...")
  end
  defp maybe_span_miner(_) do
    IO.puts("Mining disabled.")
  end

  def index(conn, _params) do
    maybe_spawn_miner(ConcurrentCount.Environment.get_bool_env("mine", false))

    GenServer.call(Counter, {:open})
    :ok = :timer.sleep(get_delay())
    {open, peak, started, finished, node} = GenServer.call(Counter, {:close})
    {mineRunning, mineCount, minMine, maxMine, mineTime, _} = GenServer.call(Miner, {:inspect})
    averageMine = average(mineTime, mineCount)

    render conn, "index.html",
        open: open + 1, peak: peak, started: started,
        finished: finished, node: node,
        mineCount: mineCount, minMine: minMine,
        maxMine: maxMine, mineTime: mineTime,
        averageMine: averageMine, mineRunning: mineRunning
  end
end
