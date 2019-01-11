defmodule ConcurrentCountWeb.PageController do
  use ConcurrentCountWeb, :controller

  defp get_delay() do
    ConcurrentCount.Environment.get_int_env("DELAY", 250)
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
  defp maybe_spawn_miner(_) do
    IO.puts("Mining disabled.")
  end

  def clearPutCache(conn, _params) do
    GenServer.call(PutCache, {:clear})
    render conn, "put.html"
  end

  def putHandler(conn, params) do
    GenServer.call(PutCache, {:put, params})
    IO.puts("Received put message, storing contents.")
    render conn, "put.html"
  end

  def index(conn, _params) do
    do_mine = ConcurrentCount.Environment.get_bool_env("mine", false)
    maybe_spawn_miner(do_mine)

    GenServer.call(Counter, {:open})
    :ok = :timer.sleep(get_delay())
    {open, peak, started, finished, node} = GenServer.call(Counter, {:close})
    {mineRunning, mineCount, minMine, maxMine, mineTime, _} = GenServer.call(Miner, {:inspect})
    averageMine = average(mineTime, mineCount)

    {putSize, putMessages} = GenServer.call(PutCache, {:inspect})

    render conn, "index.html",
        open: open + 1, peak: peak, started: started,
        finished: finished, node: node,
        showMine: do_mine,
        mineCount: mineCount, minMine: minMine,
        maxMine: maxMine, mineTime: mineTime,
        averageMine: averageMine, mineRunning: mineRunning,
        putSize: putSize, putMessages: putMessages
  end
end
