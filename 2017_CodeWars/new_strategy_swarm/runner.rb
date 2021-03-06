require './my_strategy'
require './remote_process_client'

class RemoteProcessClient
  def read_bytes(byte_count)
    byte_array = ''

    while byte_array.length < byte_count
      chunk = @socket.recv(byte_count - byte_array.length)
      raise IOError, "Can't read #{byte_count} bytes from input stream." if chunk.length == 0
      byte_array << chunk # << is WAY faster than +=
    end

    byte_array
  end
end

class Runner
  def initialize

    system 'cd ../local-runner-ru/ && ./local-runner.sh'
    sleep(2)

    if ARGV.length == 3
      @remote_process_client = RemoteProcessClient::new(ARGV[0], ARGV[1].to_i)
      @token = ARGV[2]
    else
      @remote_process_client = RemoteProcessClient::new('127.0.0.1', 31001)
      @token = '0000000000000000'
    end
  end

  def run
    begin
      @remote_process_client.write_token_message(@token)
      @remote_process_client.write_protocol_version_message
      @remote_process_client.read_team_size_message
      game = @remote_process_client.read_game_context_message

      strategy = MyStrategy::new

      until (player_context = @remote_process_client.read_player_context_message).nil?
        player = player_context.player
        break if player.nil?

        move = Move::new
        strategy.move(player, player_context.world, game, move)

        @remote_process_client.write_move_message(move)
      end
    ensure
      @remote_process_client.close
    end
  end
end

Runner.new.run
