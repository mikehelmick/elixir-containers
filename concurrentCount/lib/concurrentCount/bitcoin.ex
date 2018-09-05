defmodule ConcurrentCount.Bitcoin do
  import ConcurrentCount.Environment

  defp fact(1, acc) do
    acc
  end
  defp fact(n, acc) do
    fact(n - 1, n * acc)
  end

  defp maybe_mine({:error, curRunning}) do
    IO.puts("Skipping mining, #{curRunning} requests in process")
  end
  defp maybe_mine({:ok, _}) do
    target = get_int_env("factorial", 1000)
    IO.puts("Starting to mine... ")
    start_time = System.os_time(:millisecond)
    _f = fact(target, 1)
    end_time = System.os_time(:millisecond)
    IO.puts("Calculated fact(#{target}) in #{end_time - start_time} ms")
    GenServer.call(Miner, {:done_mining, end_time - start_time})
  end

  def mine() do
    maybe_mine(GenServer.call(Miner, {:maybe_mine}))
  end

end
