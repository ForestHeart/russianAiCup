module MyHelper

  DEBUG = true

  def update_all_vechicles
    @world.new_vehicles.each do |vechicle|
      @all_vechicles[vechicle.id] = vechicle
    end

    @world.vehicle_updates.each do |vechicle|
      @all_vechicles[vechicle.id].update(vechicle) if @all_vechicles[vechicle.id]
    end
  end

  def update_group_position
    @enemy_groups.each do |k, group|
      update_group(group)
    end

    @my_groups.each do |k, group|
      update_group(group)
    end
  end

  def update_group(group)
    vechicle_ids = group.vechicle_ids
    x = 0
    y = 0

    sum = 0
    speed = Vector[0,0]
    avrg_speed = Vector[0,0]

    vechicle_ids.each do |id|
      next if @all_vechicles[id].durability < 0.1

      x += @all_vechicles[id].x
      y += @all_vechicles[id].y

      sum += 1
      speed += @all_vechicles[id].speed

      vechicle_avg_speed = Vector[0,0]
      @all_vechicles[id].speed_array.each{ |s| vechicle_avg_speed += s }

      avrg_speed += vechicle_avg_speed / @all_vechicles[id].speed_array.size

    end

    return nil if sum.zero?

    speed = speed / sum
    avrg_speed = avrg_speed / sum

    x = x / sum
    y = y / sum

    position_vector = Vector[x.to_i, y.to_i]

    params = OpenStruct.new(position: position_vector, speed: speed, avrg_speed: avrg_speed)

    group.update_params(params)
  end


  def vision_factor(vechicle)
    factor = 1

    if GROUND_TYPE.include?(vechicle.type)
      my_terrain_type = @world.terrain_by_cell_x_y[(vechicle.x/32).to_i][(vechicle.y/32).to_i]
      if my_terrain_type == TerrainType::FOREST
        factor = 0.8
      else
        factor = 1
      end
    else
      my_whether_type = @world.weather_by_cell_x_y[(vechicle.x/32).to_i][(vechicle.y/32).to_i]
      if my_whether_type == WeatherType::RAIN
        factor = 0.6
      elsif my_whether_type == WeatherType::RAIN
        factor = 0.8
      else
        factor = 1
      end
    end

    factor
  rescue => e
    0.77
  end


  # ================================================================================
  #                        DELAYED AND SHEDULED MOVES
  # ================================================================================


  def execute_delayed_move
    return nil if @me.remaining_action_cooldown_ticks > 0

    print 'D' if DEBUG
    @last_print = 'D'

    delay_move = @delayed_moves.shift
    return nil unless delay_move

    if delay_move.action_type == ActionType::CLEAR_AND_SELECT
      if delay_move.select_group == @selected
        p 'Alredy selected group: ' + @selected.to_s + ', skip'

        if @delayed_moves.any?
          execute_delayed_move
        end

        return nil
      end

      @selected = delay_move.select_group
    end


    delay_move.proc.call
  end

  def add_move(delayed_move)
    if @sheduled_tick.to_i > 0
      delayed_move.tick += @sheduled_tick
    end

    @sheduled_moves << delayed_move
  end

  # def run_strategies
  #   @strategies.each do |strategy|
  #     if strategy.run?(world.tick_index)
  #       p 'Run strategy group: ' + strategy.group.to_s + ', name: '+ strategy.f_name.to_s
  #       self.send(strategy.f_name, strategy)
  #     end
  #   end
  # end

  def check_sheduled_move
    to_delete = []

    @sheduled_moves.each_index do |i|
      sheduled_move = @sheduled_moves[i]
      if @world.tick_index >= sheduled_move.tick
        @delayed_moves << sheduled_move

        to_delete << i
      end
    end

    while to_delete.any? do
      i = to_delete.pop
      @sheduled_moves.delete_at(i)
    end
  end

  # ================================================================================
  #                       DEGBUG
  # ================================================================================

  def awesome_print(value, n = 0)
    p '' if n == 0

    text = '  '*n
    if value.is_a?(Array || Hash)
      text += value.class.name + ': '
      p text
      value.each do |el|
        awesome_print(el, n + 1)
      end
    else
      text += value.inspect
      p text
    end

    p '' if n == 0

  end

  def p text
    if DEBUG
      text = "\n" + text if @last_print == 'D'
      @last_print = 'p'
      puts text
    end
  end
end
