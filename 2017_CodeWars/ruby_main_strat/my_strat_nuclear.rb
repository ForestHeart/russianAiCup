
module MyStratNuclear

  def nuke_debug
    false
  end

  def call_the_nuke(strategy)

    return nil if @nuke_avoiding

    # p 'nuke = ' + me.remaining_nuclear_strike_cooldown_ticks.to_s if me.remaining_nuclear_strike_cooldown_ticks % 50 == 0

    return nil if me.remaining_nuclear_strike_cooldown_ticks > 0 || me.next_nuclear_strike_vehicle_id > 0

    enemy_recs = enemy_position
    return nil unless enemy_recs.any?

    targets = []
    unavailable_targets = []

    my_rec = get_reactangle_by_type(strategy.group)

    enemy_recs.each do |enemy_rec|
      nearest_enemy = find_nearest_vehicle(my_rec.x, my_rec.y, enemy_rec.type, false)
      nearest_my = find_nearest_vehicle(nearest_enemy.x, nearest_enemy.y, my_rec.type, true)

      # Double presicion


      nearest_enemy = find_nearest_vehicle(nearest_my.x, nearest_my.y, enemy_rec.type, false)
      nearest_my = find_nearest_vehicle(nearest_enemy.x, nearest_enemy.y, my_rec.type, true)

      next if nearest_enemy.nil? || nearest_my.nil?

      distance = nearest_enemy.distance_to_unit(nearest_my)

      if nuke_debug
        p 'distance: ' + distance.to_i.to_s
        p 'nearest_my x: ' + nearest_my.x.to_i.to_s + ' y: ' + nearest_my.y.to_i.to_s
        p 'nearest_enemy x: ' + nearest_enemy.x.to_i.to_s + ' y: ' + nearest_enemy.y.to_i.to_s
      end

      max_nuke_distance = 100

      if @fog
        max_nuke_distance = vision_factor(nearest_my) * (nearest_my.vision_range) - 40
      end

      next if distance > max_nuke_distance

      next if my_rec.size < 5 && distance < 30

      step = 10 # шаг ячейки
      n = 10   # количество ячеек
      for i in 0..n
        for j in 0..n

          nn = (n.to_f / 2).round

          x = nearest_enemy.x + ((i-n/2)*step)
          y = nearest_enemy.y + ((j-n/2)*step)

          nearest_my_to_nuke = find_nearest_vehicle(x, y, strategy.group, true)
          nearest_distance = nearest_my_to_nuke.distance_to(x, y)

          min_dist = 5

          min_dist = -1 if my_rec.size < 5 && strategy.nuker = true

          nuke_vechicle = find_nuke_vehicle(x, y, strategy.group, nearest_distance + min_dist, distance + 20)

          profit = nuke_profit(x, y)

          min_nuke_size = 10
          min_nuke_points = 300
          if @fog
            if @world.tick_index <= 2_000
              min_nuke_points = 3000
              min_nuke_size =  40
            elsif @world.tick_index <= 5_000
              min_nuke_points = 2000
              min_nuke_size =  30
            elsif @world.tick_index <= 10_000
              min_nuke_points = 1000
              min_nuke_size =  20
            end
          end

          next if profit.points <= min_nuke_points || profit.enemy_size <= min_nuke_size

          p 'profit: ' + profit.inspect if nuke_debug

          if nuke_vechicle.nil?
            unavailable_targets << OpenStruct.new(x:x, y:y, profit: profit.points, vechicle: nuke_vechicle)
          else
            targets << OpenStruct.new(x:x, y:y, profit: profit.points, vechicle: nuke_vechicle)
          end


        end
      end

    end



    if targets.any?

      p 'targets: '
      awesome_print targets.sort_by{|t| t.profit}.last
      awesome_print unavailable_targets.sort_by{|t| t.profit}.last

      # binding.pry


      target = targets.sort_by{|t| t.profit}.last

      unavailable_profit = 0

      if unavailable_targets.any?
        unavailable_profit = unavailable_targets.sort_by{|t| t.profit}.last.profit
      end

      return nil if unavailable_profit > (target.profit * 1.5)

      # binding.pry

      @add_before_moves = true

      nuclear_strike(target.x, target.y, target.vechicle)

      @add_before_moves = false

      if @world.tick_index > 0 || !strategy.group.nil?

        unless target.vechicle.groups.any?
          @sheduled_tick = 1
          move_by_type(0, 0, strategy.group)
          @sheduled_tick = 15
          move_by_type(0, 0, strategy.group)
          @sheduled_tick = 0
        end

        target.vechicle.groups.each do |group|
          @stop_list = OpenStruct.new(group: group, tick: @world.tick_index + 30)

          @sheduled_tick = 1
          move_by_type(0, 0, group)
          @sheduled_tick = 15
          move_by_type(0, 0, group)
          @sheduled_tick = 0
        end

        # @stop_list = OpenStruct.new(group: strategy.group, tick: @world.tick_index + 30)

      end

    end
  rescue => e
    puts '================================================================================='
    puts "An error of type #{e.class} happened, message is #{e.message}"
    puts '================================================================================='

    if @debug
      raise e
    end
  end


  def avoid_nuke

    player = @world.opponent_player

    # player = @world.my_player

    if player.next_nuclear_strike_tick_index > 0 && @nuke_avoiding == false && @me.remaining_action_cooldown_ticks == 0

      nuke_r = 100

      @nuke_avoiding = true

      # binding.pry

      p 'Avoid nuke' if nuke_debug

      x = player.next_nuclear_strike_x
      y = player.next_nuclear_strike_y

      # insert at first move
      @add_before_moves = true

      set_group(99)

      delayed_move = @move.clone
      delayed_move.action = ActionType::SCALE
      delayed_move.x = x
      delayed_move.y = y
      delayed_move.factor = 10
      add_move(delayed_move)

      select_area(x - nuke_r, y - nuke_r, x + nuke_r, y + nuke_r )

      @add_before_moves = false

      # select_area(x - nuke_r, y - nuke_r, x + nuke_r, y + nuke_r )

      # delayed_move = @move.clone
      # delayed_move.action = ActionType::SCALE
      # delayed_move.x = x
      # delayed_move.y = y
      # delayed_move.factor = 10
      # add_move(delayed_move)

      # set_group(99)

      @sheduled_tick = 30
      scale_from_x_y_by_type(x, y, 0.1, 99)

      @sheduled_tick = 60
      move_by_type(0,0, 99)

      @sheduled_tick = 0

      # stop my nuke vechicle
      if @world.my_player.next_nuclear_strike_vehicle_id.to_i > 0
        nuke_vechicle = @all_vechicles[@world.my_player.next_nuclear_strike_vehicle_id.to_i]

        select_area(nuke_vechicle.x - 2, nuke_vechicle.y - 2, nuke_vechicle.x + 2, nuke_vechicle.y + 2)
        move_selected(0,0)
      end

      selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id &&(v.x - x).abs < nuke_r && (v.y - y).abs < nuke_r && v.durability > 1}

      group_ids = []

      selected_vechicles.each do |k,v|
        group_ids << v.groups if v.groups.any?
      end

      p 'group_ids:'  + group_ids.flatten.uniq.inspect if nuke_debug

      group_ids.flatten.uniq.each do |group_id|
        @stop_list = OpenStruct.new(group: group_id, tick: @world.tick_index + 60)
      end

      prc = Proc.new do
        @nuke_avoiding = false
        select_all(99)
        dismiss_selected(99)
      end
      shedule_proc(prc, 70)

    end

  end

end
