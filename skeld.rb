require './skel_control.rb'

def skeld(opts)
  ctl = SkelCtlSrvSocket.setup
  exit 1 if ctl.nil?

  init_signals

  $use_sigerr = false
  $sig_exit = false
  $sig_reload = false
  quit = false

  while not quit
    cmd = nil

    rs = ws = []
    begin
      $use_sigerr = true
      if $sig_exit
        quit = true
        next
      end

      rs, ws = IO.select([ctl], [], [], nil)
      $use_sigerr = false
    rescue SignalError => e
      $stderr.puts "Caught signal: #{e}"
      $use_sigerr = false
    rescue => e
      $stderr.puts e.full_message
      $use_sigerr = false
      quit = true
    end

    unless rs.nil?
      rs.each do |sock|
        case sock
        when SkelCtlSrvSocket
          cmd = sock.accept_and_recv
          status = process_control(sock, cmd)
          sock.disconnect
          quit = true if status == :exit
        end
      end
    end

    quit = true if $sig_exit
  end
  ctl.teardown
end

def init_signals
  Signal.trap(:INT)  { sighandler(:INT) }
  Signal.trap(:QUIT) { sighandler(:QUIT) }
  Signal.trap(:TERM) { sighandler(:TERM) }
  Signal.trap(:HUP)  { sighandler(:HUP) }
end

def sighandler(sig)
  case sig
  when :HUP
    $sig_reload = true
  else
    $sig_exit = true
  end

  raise SignalError, "#{sig}" if $use_sigerr
end

class SignalError < StandardError; end

def process_control(ctl, cmd)
  return :none unless cmd.is_a?(Hash)

  case cmd["command"]
  when SkelControl::CMD_EXIT
    :exit
  when SkelControl::CMD_TEST
    ctl.response("OK")
  else
    :none
  end
end

if $0 == __FILE__
  skeld(ARGV)
end
