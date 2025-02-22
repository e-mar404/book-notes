defmodule DatabaseServer do
  def start do
    spawn(fn ->
      connection = :rand.uniform(1000)
      loop(connection)
    end)
  end

  defp loop(connection) do
    receive do
      {:run_query, caller, query} ->
        query_result = run_query(connection, query)
        send(caller, {:query_result, query_result})
    end

    loop(connection)
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

  defp run_query(connection, query) do
    Process.sleep(1000)
    "Connection: #{connection} #{query} result"
  end
end
