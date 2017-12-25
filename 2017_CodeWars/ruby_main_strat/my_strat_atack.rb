
module MyStratAtack

  # ============================ ROTATING ==========================
  def atack_rotate(strategy, distance)
    return false if strategy.no_scaling_and_rotating

    if strategy.rotated_since >= 30 && distance > 50 && !@kover
      strategy.min_tick = @world.tick_index.to_i + 40


      rotate_from_center_by_type(1.7 * strategy.rotated_angle, nil, strategy.group)
      p 'rotating'

      strategy.rotated_angle = strategy.rotated_angle * -1
      strategy.rotated_since = 0

      strategy.move_to_x = -500
      strategy.move_to_y = -500

      return true
    end

    return false
  end


  # ========================== SCALING ===============================
  def atack_scale(strategy, distance)

    return false if strategy.no_scaling_and_rotating

    if (strategy.scaled_since >= 30 && distance > 100  && !@kover ) || (strategy.scaled_since >= 15 && distance > 30 && distance < 200  && !@kover)
      strategy.min_tick = @world.tick_index.to_i + 40
      scale_from_center_by_type(0.1, strategy.group)
      p 'scale'

      strategy.scaled_since = 0

      strategy.move_to_x = -500
      strategy.move_to_y = -500

      return true
    end

    return false
  end

  # =================================== COMPACTING ===================================
  def atack_compacting(strategy, distance, my_rec)

    return false if strategy.no_scaling_and_rotating

    max_wide = Math.sqrt(my_rec.size)*strategy.compacting_k

    if my_rec.size > 2 && ((distance > 30 && strategy.scaled_since > 7 && !@kover) || (distance < 30 && strategy.scaled_since > 30)) && ( max_wide < my_rec.width_x ||  max_wide < my_rec.width_y )
      p 'to wide, compacting, group: ' + strategy.group.to_s

      strategy.min_tick = @world.tick_index.to_i + 140

      scale_from_center_by_type(1.1, strategy.group)

      @sheduled_tick = 21

      strategy.rotated_angle = strategy.rotated_angle * -1

      rotate_from_center_by_type(1.7 * strategy.rotated_angle, nil, strategy.group)

      @sheduled_tick = 60

      scale_from_center_by_type(0.1, strategy.group)
      # puts 'rotating'


      strategy.rotated_since = 5
      strategy.scaled_since = 0

      if @kover
        @sheduled_tick = 100
        scale_from_center_by_type(1.1, strategy.group)
      end

      @sheduled_tick = 0

      strategy.move_to_x = -500
      strategy.move_to_y = -500

      return true
    end

    return false
  end

  # =================================== Go HEALING ===================================
  def go_healing(strategy, my_rec)
    return false unless strategy.healing

    # p ''
    # p 'HEALING INFO'
    # p 'percent: ' + (my_rec.durability / my_rec.size).to_s + '  need_healing_size: ' + my_rec.need_healing_size.to_s
    # p 'need_durability: ' + ((100 * my_rec.size) - my_rec.durability ).to_s
    # p ''


    if my_rec.durability / my_rec.size > 90 || my_rec.need_healing_size < 3 || strategy.need_durability < 100
      strategy.start_healing = false
    end

    if ( (my_rec.durability / my_rec.size < strategy.healing_percent || my_rec.need_healing_size >= strategy.need_healing_size || (100 * my_rec.size - my_rec.durability) >= strategy.need_durability ) ) || strategy.start_healing

      nearest_health = find_nearest_vehicle(my_rec.x, my_rec.y, VehicleType::ARRV, true)

      return false if nearest_health.nil?
      nearest_my = find_nearest_vehicle(nearest_health.x, nearest_health.y, strategy.group, true)
      # return false if nearest_my

      p 'Go healing stratagy : ' + strategy.group.to_s

      strategy.move_to_x = -500
      strategy.move_to_y = -500

      target_distance = 3

      distance = nearest_health.distance_to(my_rec.x, my_rec.y)

      if distance < target_distance
        # puts 'min'
        x = (my_rec.x - nearest_health.x) * (target_distance - distance) / target_distance
        y = (my_rec.y - nearest_health.y) * (target_distance - distance) / target_distance
      else
        # puts 'norm'
        x = (nearest_health.x - my_rec.x) * (distance - target_distance) / distance
        y = (nearest_health.y - my_rec.y) * (distance - target_distance) / distance
      end

      if x.abs + y.abs < 5

        strategy.start_healing = true

        if (strategy.scaled_since >= 5 )
          strategy.min_tick = @world.tick_index.to_i + 50
          scale_from_center_by_type(0.1, strategy.group, 0.5)
          p 'healing scale'
          strategy.scaled_since = 0

          @sheduled_tick = 40
          scale_from_center_by_type(1.1, strategy.group)

          @sheduled_tick = 0

          return true
        end


        rotate_from_center_by_type(1.7 * strategy.rotated_angle, nil , strategy.group)
        strategy.min_tick = @world.tick_index.to_i + 40
      else
        move_by_type(x, y, strategy.group, strategy.max_speed) if x.abs + y.abs > 1
      end

      return true

    end

    return false
  end

  # ============================================================================
  # =================================== MAIN ===================================
  # ============================================================================
  def atack_nearest(strategy)

    strategy.rotated_since += 1
    strategy.scaled_since += 1

    strategy.last_move = @world.tick_index

    my_rec = get_reactangle_by_type(strategy.group)

    # binding.pry if @world.tick_index > 1400

    nearest_enemy = find_nearest_enemy(my_rec.x, my_rec.y, strategy.atack_unity_types)

    target_distance = strategy.target_distance

    if nearest_enemy.nil?
      # binding.pry
      nearest_enemy = find_nearest_enemy(my_rec.x, my_rec.y, strategy.second_atack_unity_types)
      target_distance = strategy.second_target_distance
    end


    if my_rec.size == 0
      remove_strategy(strategy.group)
      return nil
    end

    #  =============== CHECK go HEALING ==================
    return nil if go_healing(strategy, my_rec)

    # return nil if nearest_enemy.nil?

    # ===================== keep alive =====================
    if strategy.keep_alive && (my_rec.size <= strategy.keep_alive_size || my_rec.durability <= strategy.keep_alive_durability) && !strategy.keeping_alive
      strategy.atack_unity_types = nil
      strategy.target_distance = strategy.keep_alive_distance
      strategy.atack_rotating = false
      strategy.keeping_alive = true

      target_distance = strategy.keep_alive_distance
    end

    if !nearest_enemy.nil?

      nearest_my = find_nearest_vehicle(nearest_enemy.x, nearest_enemy.y, strategy.group, true)

      # double quality
      nearest_enemy = find_nearest_vehicle(nearest_my.x, nearest_my.y, nearest_enemy.type, false)
      nearest_my = find_nearest_vehicle(nearest_enemy.x, nearest_enemy.y, strategy.group, true)

      return nil if nearest_enemy.nil? || nearest_my.nil?

      distance = nearest_enemy.distance_to_unit(nearest_my)

      strategy.mod_tick = strategy.mod_tick_slow if distance > 300
      strategy.mod_tick = strategy.mod_tick_mid if distance >= 100 && distance < 300
      strategy.mod_tick = strategy.mod_tick_fast if distance < 100
    else
      distance = 5000
    end


    return nil if atack_compacting(strategy, distance, my_rec)

    return nil if atack_scale(strategy, distance)

    return nil if atack_rotate(strategy, distance)

    # binding.pry
    # raise 'stop'

    # ===================== FACILITIES =====================
    if @world.facilities.size > 0 && strategy.capture_facility && distance > 30
      selected_facilities = @world.facilities.select{ |f| f.owner_player_id != @me.id}

      # свои, наполовину не захваченные
      selected_facilities += @world.facilities.select{ |f| f.owner_player_id == @me.id && f.capture_points < 80}

      if selected_facilities.size > 0
        nearest_facility = selected_facilities.min_by{|f| ((f.left + 32 - my_rec.x)**2 + (f.top + 32 - my_rec.y)**2) * (2 - f.type) }

        # puts 'Nearest facility: ' + nearest_facility.inspect

        facility_distance = Math.sqrt((nearest_facility.left + 32 - my_rec.x)**2 + (nearest_facility.top + 32 - my_rec.y)**2)

        @global_facility_distance_k = 20 if @kover

        if facility_distance < distance * strategy.facility_distance_k * @global_facility_distance_k

          strategy.mod_tick = strategy.mod_tick_slow if facility_distance > 200
          strategy.mod_tick = strategy.mod_tick_mid if facility_distance >= 50 && facility_distance < 200

          p 'go to facility: ' + nearest_facility.id.to_s

          x = nearest_facility.left + 32 - my_rec.x
          y = nearest_facility.top + 32 - my_rec.y

          diff_pos = (x + my_rec.x - strategy.move_to_x)**2 + (y + my_rec.y - strategy.move_to_y)**2
          angle_diff = angle_between(x + my_rec.x, y + my_rec.y, strategy.move_to_x, strategy.move_to_y)

          p 'angle_diff: ' + angle_diff.to_s

          if (diff_pos < 10**2 && facility_distance > 100 && my_rec.speed > 0.1) || (diff_pos < 2**2 && facility_distance > 30 && my_rec.speed > 0.1) || (angle_diff < 5 && facility_distance > 50 && my_rec.speed > 0.1)
            p 'SKIP move to, the same way'
          else
            p 'go to x:' + x.to_s + ' y:' + y.to_s
            move_by_type(x, y, strategy.group, strategy.max_speed) if facility_distance > 10
            strategy.move_to_x = x + my_rec.x
            strategy.move_to_y = y + my_rec.y
          end

          # puts 'Move to facility: ' + nearest_facility.inspect

          return true
        end
      end
    end

    # ===================== AVOID AGRESSIVE =====================

    if distance < 400 && strategy.avoid_agressive && !@kover && !nearest_enemy.nil?
      aggresive_calc = calculate_aggresive(strategy, nearest_enemy.x, nearest_enemy.y)

      # binding.pry if aggresive_calc.size > 0

      p 'calc aggresive'

      if aggresive_calc.between_size > 15
        # puts 'aggresive 60'
        target_distance = 70 if target_distance < 70
      elsif aggresive_calc.between_size > 5
        # puts 'aggresive 40'
        target_distance = 50 if target_distance < 50
      elsif aggresive_calc.size > 5
        # puts 'aggresive 12'
        target_distance = 25 if target_distance < 25
      end

      agressive_everywhere = false

      my_aggresive_calc = calculate_aggresive(strategy, my_rec.x, my_rec.y)

      if my_aggresive_calc.size > 10

        strategy.mod_tick = strategy.mod_tick_fast
        ranges = [0, -100, 100]

        for x in ranges
          for y in ranges

            next if x == 0 && y == 0

            agressives = []

            my_aggresive_calc = calculate_aggresive(strategy, my_rec.x + x, my_rec.y + y)
            if my_aggresive_calc.size < 10 && (x + y > 0)

              agressives << {x: x, y: y, size: my_aggresive_calc.size}

            end
          end
        end

        if agressives.any?

          min_agr = agressives.sort_by{|a| a.size}.first

          p 'too aggresive, move back'
          move_by_type(min_agr[:x], min_agr[:y], strategy.group, strategy.max_speed)

          strategy.move_to_x = -500
          strategy.move_to_y = -500

          return true
        end

        # не нашли шагов без агрессии, вероятно Ковер?
        agressive_everywhere = true
        target_distance = strategy.target_distance

      end

    end

    # ============= Patrol the FOG ==============================
    if nearest_enemy.nil?

      if (strategy.fog_x - my_rec.x).abs < 5
        if strategy.fog_x > @world.width / 2
          strategy.fog_x = 50
        else
          strategy.fog_x = @world.width - 50
        end
      end

      if (strategy.fog_y - my_rec.y).abs < 5
        if strategy.fog_y > @world.height / 2
          strategy.fog_y = 50
        else
          strategy.fog_y = @world.height - 50
        end
      end

      p 'patrol'

      move_to_by_type(strategy.fog_x, strategy.fog_y, strategy.group, strategy.max_speed)

      return nil
    end

    p 'distance: ' + distance.to_s
    p 'target_distance: ' + target_distance.to_s

    distance = 0.1 if distance <= 0.1

    if distance < target_distance
      # puts 'min'
      x = (nearest_my.x - nearest_enemy.x) * (target_distance - distance) / target_distance
      y = (nearest_my.y - nearest_enemy.y) * (target_distance - distance) / target_distance
    else
      # puts 'norm'
      x = (nearest_enemy.x - nearest_my.x) * (distance - target_distance) / distance
      y = (nearest_enemy.y - nearest_my.y) * (distance - target_distance) / distance
    end

    if @kover
      p 'kover'
      x += x*1.3
      y += y*1.3
    end

    # Проверяем границы

    # x += 10 if x + my_rec.min_x < 5
    # y += 10 if y + my_rec.min_y < 5

    # x -= 10 if x + my_rec.max_x > @world.width - 5
    # y -= 10 if y + my_rec.max_y > @world.height - 5

    # p 'distance: ' + distance.to_i.to_s
    # p 'my rec x: ' + my_rec.x.to_i.to_s + ' y: ' + my_rec.y.to_i.to_s
    # p 'enemy_rec x: ' + enemy_rec.x.to_i.to_s + ' y: ' + enemy_rec.y.to_i.to_s
    p 'nearest_enemy x: ' + nearest_enemy.x.to_i.to_s + ' y: ' + nearest_enemy.y.to_i.to_s

    # p 'go to x: ' + x.to_i.to_s + ' y: ' + y.to_i.to_s

    p 'distance ' + distance.to_s
    p 'target_distance ' + target_distance.to_s


    # puts 'nearest enemy x:' + nearest_enemy.x.to_s + ' y:' + nearest_enemy.y.to_s
    # puts 'nearest_my x:' + nearest_my.x.to_s + ' y:' + nearest_my.y.to_s

    p 'my x:' + my_rec.x.to_s + ' y:' + my_rec.y.to_s

    if strategy.atack_rotating && (x**2 + y**2) < 25
      rotate_from_center_by_type(1.7 * strategy.rotated_angle, nil , strategy.group)
    else

      movement_distance = Math.sqrt(x**2 + y**2)

      diff_pos = (x + my_rec.x - strategy.move_to_x)**2 + (y + my_rec.y - strategy.move_to_y)**2

      angle_diff = angle_between(x + my_rec.x, y + my_rec.y, strategy.move_to_x, strategy.move_to_y)

      p 'diff_pos: ' + diff_pos.to_s
      p 'angle_diff: ' + angle_diff.to_s
      p 'target x:' + (x + my_rec.x).to_s + ' y:' + (y + my_rec.y).to_s
      p 'last target x:' + strategy.move_to_x.to_s + ' y:' + strategy.move_to_y.to_s

      p 'speed :' + my_rec.speed.to_s


      if (diff_pos < 10**2 && distance > 100 && my_rec.speed > 0.1) || (diff_pos < 2**2 && distance > 30 && my_rec.speed > 0.1) || (angle_diff < 10 && distance > 100 && movement_distance > 100 && my_rec.speed > 0.1) || (angle_diff < 5 && distance > 50 && movement_distance > 50 && diff_pos < 5 && my_rec.speed > 0.1)
        p 'SKIP move to, the same way'
      else
        p 'go to x:' + x.to_s + ' y:' + y.to_s
        move_by_type(x, y, strategy.group, strategy.max_speed) if x.abs + y.abs > 2
        strategy.move_to_x = x + my_rec.x
        strategy.move_to_y = y + my_rec.y
      end


    end


  end


end
