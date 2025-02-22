defmodule DatabaseServer do
  def start do
    spawn(&loop/0) # this is were we get the server pid
  end

  defp loop do
    receive do
      {:run_query, caller, query} ->
        query_result = run_query(query)
        send(caller, {:query_result, query_result})
    end

    loop()
  end

  def run_async(server_pid, query) do
    send(server_pid, {:run_query, self(), query})
  end

  def get_result do
    receive do
      {:query_result, result} -> result
    after 
      5000 -> {:error, :timeout}
    end
  end

  defp run_query(query) do
    Process.sleep(1000)
    "#{query} result"
  end
end
