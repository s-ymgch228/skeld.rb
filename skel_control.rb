require 'socket'
require 'json'

class SkelControl
  PATH="/tmp/skeld.sock"
  CMDBUF_SIZ = 1024

  CMD_TEST = 0
  CMD_EXIT = 1
end

class SkelCtlSrvSocket < Socket
  def initialize
    super(Socket::AF_UNIX, Socket::SOCK_STREAM)
    @client = nil
  end

  def self.setup
    path = SkelControl::PATH
    addr = Socket.sockaddr_un(path)
    obj = self.new()

    File.unlink(path) if File.exist?(path)
    obj.bind(addr)
    obj.listen(1)
    obj
  rescue => e
    $stderr.puts "Control socket: #{e}"
    obj.close unless obj.nil?
    nil
  end

  def teardown
    close
  end

  def accept_and_recv
    @client, _from = accept()
    j = @client.recv(SkelControl::CMDBUF_SIZ)
    JSON.load(j)
  end

  def disconnect
    @client.close unless @client.nil?
    @client = nil
  end

  def response(str)
    return if @client.nil?

    @client.puts(str)
  end
end

class SkelCtlCliSocket < Socket
  def self.connect
    addr = Socket.sockaddr_un(SkelControl::PATH)
    obj = self.new(Socket::AF_UNIX, Socket::SOCK_STREAM)
    obj.connect(addr)

    yield obj

    obj.close
  end

  def send_command(h)
    j = JSON.dump(h)
    write(j)
  end

  def get_response
    gets
  end
end
