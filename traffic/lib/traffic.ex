defmodule Traffic do

  defp increment(nil), do: {nil, 1}
  defp increment(val), do: {val, val + 1}

  def receiver(pid, expected, {requests, max_observed, error_count}) when expected < 2 do
    IO.puts("End: #{Time.utc_now()}")
    IO.puts("Num requests total")
    IO.inspect requests
    IO.puts("Num requests concurrent max")
    IO.inspect max_observed
    IO.puts("Total instances observed: #{map_size(max_observed)}")
    IO.puts("Number of errors seen")
    IO.inspect error_count
    send(pid, {:done})
  end
  def receiver(pid, expected, {requests, max_observed, errors}) do
    receive do
      {_from, :ack, {server, observed}} ->
        {_, requests} = Map.get_and_update(requests, server, &increment/1)
        {_, max_observed} = Map.get_and_update(max_observed, server,
          fn
            val when is_nil(val) -> {nil, observed}
            val -> {val, max(val, observed)}
          end)
        receiver(pid, expected - 1, {requests, max_observed, errors})
      {from, :error, code} ->
        {_, errors} = Map.get_and_update(errors, code, &increment/1)
        IO.puts("Error: from #{inspect(from)} -> #{inspect(errors)}")
        receiver(pid, expected - 1, {requests, max_observed, errors})
    end
  end

  def requester(_receiver_pid, 0, requester_number) do
    IO.puts("Requester process done \##{requester_number}.")
  end
  def requester(receiver_pid, requests_to_go, requester_number) do
     url = 'https://counter-4ism2lxo6q-uc.a.run.app/'
     {:ok, result} = :httpc.request(:get, {url, []}, [], [])
     {{_, return_code, _}, _headers, body} = result
     case return_code do
       503 ->
        send(receiver_pid, {self(), :error, 503})
        requester(receiver_pid, requests_to_go - 1, requester_number)
       500 ->
        IO.puts("ERROR body #{inspect(body)}")
        send(receiver_pid, {self(), :error, 500})
        requester(receiver_pid, requests_to_go - 1, requester_number)
       200 ->
         # parse body
         [_, _, _, _, _, _, _, _, req, _, _, node | _] = String.split(to_string(body), "\n")
         [_, num] = String.split(req)
         num = Integer.parse(num)
         # send to receiver_pid
         send(receiver_pid, {self(), :ack, {node, num}})
         requester(receiver_pid, requests_to_go - 1, requester_number)
     end
  end

  def start_requesters(_, 0, _) do
    :ok
  end
  def start_requesters(receiver_pid, procs, requests) do
    spawn fn() -> requester(receiver_pid, requests, procs) end
    start_requesters(receiver_pid, procs - 1, requests)
  end

  def load_test do
    IO.puts("Starting receiver")
    main_pid = self()
    procs = 200
    requests_per = 200
    receiver_pid = spawn_link(
        fn() ->
          receiver(main_pid, procs * requests_per, {Map.new(), Map.new(), Map.new()})
        end)
    IO.puts("Starting #{procs} request processes to send #{requests_per} each")
    IO.puts("Start: #{Time.utc_now()}")
    start_time = System.os_time(:millisecond)
    start_requesters(receiver_pid, procs, requests_per)

    receive do
      {:done} ->
        IO.puts("End: #{Time.utc_now()}")
        IO.puts("Shutting down")
      x ->
        IO.puts("Main received unexpected message")
        IO.inspect(x)
    end
    end_time = System.os_time(:millisecond)
    IO.puts("Terminating.")
    IO.puts("Load test took #{end_time - start_time} ms (#{(end_time - start_time)/1000} seconds)")
    IO.puts("Average QPS: #{(procs * requests_per)/((end_time - start_time)/1000)}")
  end

  def main(_args) do
    load_test()
  end
end
