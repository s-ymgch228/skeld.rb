require './skel_control.rb'

case ARGV[0]
when "exit"
  SkelCtlCliSocket.connect() do | sock |
    cmd = {"command" => SkelControl::CMD_EXIT}
    sock.send_command(cmd)
  end
else
  SkelCtlCliSocket.connect() do | sock |
    cmd = {"command" => SkelControl::CMD_TEST}
    sock.send_command(cmd)
    puts sock.get_response
  end
end
