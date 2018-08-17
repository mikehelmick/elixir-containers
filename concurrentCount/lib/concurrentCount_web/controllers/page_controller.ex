defmodule ConcurrentCountWeb.PageController do
  use ConcurrentCountWeb, :controller

  def index(conn, _params) do
    GenServer.call(Counter, {:open})
    :ok = :timer.sleep(5000)
    {open, peak, started, finished, node} = GenServer.call(Counter, {:close})
    # Add 1 to open, count this close as being open for display purposes.
    render conn, "index.html", open: open + 1, peak: peak, started: started, finished: finished, node: node
  end
end
