defmodule SsdpClient.MulticastListener do

  def start_link(consumer_pid) do
    Task.start_link(fn -> open_and_listen(consumer_pid) end)
  end

  defp open_and_listen(consumer_pid) do
    ssdp_mcast = {239, 255, 255, 250}
    ssdp_port = 1900
    any = {0, 0, 0, 0}
    addmem_opt = {:add_membership, {ssdp_mcast, any}}
    {:ok, socket} = :gen_udp.open( ssdp_port, [{:reuseaddr, true}, addmem_opt])

    listen_to_udp(socket, consumer_pid)
  end

  defp listen_to_udp(socket, consumer_pid) do
    receive do
      {:udp, socket, host, port, msg} ->
        # forward the received packet but don't hand out the socket
        send(consumer_pid, {:udp, nil, host, port, msg}
        # continue listening for packets
        listen_to_udp(socket, consumer_pid)
      :stop ->
        :gen_udp.close(socket)
    end
  end

end
