require 'nats/client'

Thread.new do
  begin
    EM.run
  rescue Exception => e
    puts "FAILURE: #{e.class}: #{e}"
  end
end
EM.next_tick do
  NATS.start()
  Database.start
end
