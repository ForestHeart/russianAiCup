module MyStrategyAction

  # type:
  #  :airforce
  #  :tank

  def my_group_action
    @my_groups.each do |k, group|
      next if group.action == :wait
      next if @delayed_moves.select{|d| d.select_group == group.id}.any?

      next if group.wait_tick > @world.tick_index

      do_action(group)
    end
  end

  def do_action(group)

    if group.action == :atack
      enemy_group = @enemy_groups[group.target_id]

      unless enemy_group
        move_to(group, Vector[0,0])
        group.action = :wait
        group.target_id = nil
        group.move_to = Vector[0,0]

        return nil
      end

      distance = (enemy_group.position + (enemy_group.avrg_speed * 30) - group.position).r

      if distance < 300
        target = find_the_nuke_target(group, enemy_group)
        if target
          nuke_to(target.position, target.nuke_vechicle)

          move_to(group, Vector[0,0])
          group.wait_tick = @world.tick_index + 33

          return nil
        end
      end

      # binding.pry
      # raise 'stop'

      if distance < 150 && distance > 70 && @world.tick_index - group.scaled_at > 200

        scale_to(group, group.position, 0.2)

        group.scaled_at = @world.tick_index + 250

        group.wait_tick = @world.tick_index + 9
        return nil
      end


      if distance < 100 && distance > 30 && @world.tick_index - group.rotated_at > 100
        group.wait_tick = @world.tick_index + 50
        group.rotated_at = @world.tick_index

        rotate_to(group, group.position, 180)

        @sheduled_tick = @world.tick_index + 25

        rotate_to(group, group.position, 180)

        return nil
      end

      move_to(group, enemy_group.position + (enemy_group.avrg_speed * 40) - group.position)

    end
  end


  def find_the_nuke_target(my_group, enemy_group)

    p 'Find_the_nuke: '

    return nil if me.remaining_nuclear_strike_cooldown_ticks > 0 || me.next_nuclear_strike_vehicle_id > 0

    nearest_enemy = enemy_group.find_nearest_vehicle(@all_vechicles, my_group.position)
    nearest_my = my_group.find_nearest_vehicle(@all_vechicles, nearest_enemy.position)

    # p 'nearest_my x: ' + nearest_my.x.to_i.to_s + ' y: ' + nearest_my.y.to_i.to_s
    # p 'nearest_enemy x: ' + nearest_enemy.x.to_i.to_s + ' y: ' + nearest_enemy.y.to_i.to_s

    return nil if nearest_enemy.nil? || nearest_my.nil?

    distance = nearest_enemy.distance_to_unit(nearest_my)
    factor = vision_factor(nearest_my)

    # p 'distance: ' + distance.to_i.to_s
    # p 'factor: ' + factor.to_i.to_s

    return nil if distance > 90 * factor


    angles = [-30, -20, -10, 0, 10, 20, 30]
    ranges = [-20, -10, 0, 10, 20, 30, 40]
    vectors = [
      [nearest_enemy.position, nearest_my.position],
      [enemy_group.position, nearest_my.position],
      [enemy_group.position, my_group.position]
    ]

    targets = []

    angles.each do |angle_diff|
      ranges.each do |dist_diff|
        vectors.each do |vectors_arr|

          nuke_vector = vectors_arr[0] - vectors_arr[1]
          my_position = vectors_arr[1]

          next if nuke_vector.r < 1
          nuke_vector = nuke_vector.change_r(dist_diff)
          next if nuke_vector.r < 1
          nuke_vector = nuke_vector.rotate(angle_diff)

          nearest_my_to_nuke = my_group.find_nearest_vehicle(@all_vechicles, nuke_vector + my_position)
          next if nearest_my_to_nuke.nil?

          nuke_distance = (nuke_vector + my_position - nearest_my_to_nuke.position).r
          next if nuke_distance > nearest_my_to_nuke.vision_range * factor - 5

          nuke_vechicle = my_group.find_nearest_vehicle(@all_vechicles, nuke_vector + my_position, nuke_distance + 3)
          nuke_distance = (nuke_vector + my_position - nuke_vechicle.position).r
          next if nuke_distance > nuke_vechicle.vision_range * factor - 3

          profit = nuke_profit(nuke_vector + my_position)

          next if profit.points <= 1000 || profit.enemy_size <= 10
          next if profit.points / profit.enemy_size <= 20

          targets << OpenStruct.new(position: nuke_vector + my_position, profit: profit.points, nuke_vechicle: nuke_vechicle)
        end
      end
    end

    # if targets.size > 0
    #   binding.pry
    # end

    if targets.any?
      target = targets.sort_by{|t| t.profit}.first
      return target
    end

    return nil

  end

  def nuke_profit(position)
    x = position[0]
    y = position[1]

    selected_vechicles = @all_vechicles.select{|k,v| v.durability > 0 && v.squared_distance_to(x, y) <= 1800 }

    points = 0
    enemy_size = 0

    selected_vechicles.each do |id, vechicle|
      if vechicle.player_id == @me.id
        points -= vechicle.durability
      else
        points += vechicle.durability
        enemy_size += 1
      end
    end

    OpenStruct.new(points: points, enemy_size: enemy_size)

  end

end
