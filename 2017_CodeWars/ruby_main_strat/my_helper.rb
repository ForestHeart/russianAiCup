module MyHelper

  GROUND_TYPE = [0, 3, 4]
  AIR_TYPE = [1, 2]


  def update_all_vechicles
    @all_vechicles.each_value do |vechicle|
      vechicle.speed = 0
    end

    @world.new_vehicles.each do |vechicle|
      @all_vechicles[vechicle.id] = vechicle
    end

    @world.vehicle_updates.each do |vechicle|
      @all_vechicles[vechicle.id].update(vechicle) if @all_vechicles[vechicle.id]
    end
  #<VehicleUpdate:0x000000018f7b80 @id=89, @x=98.73824812240818, @y=116.73824812240761, @durability=100, @remaining_attack_cooldown_ticks=0, @selected=true, @groups=[]>
  end

  def find_first_own_vechicle
    @all_vechicles.each_value do |vechicle|
      if vechicle.player_id == @me.id && vechicle.durability > 0
        return vechicle
      end
    end

    return nil
  end

  # Options {groups, my}
  def get_units(x1, x2, y1, y2, options={})

    # groups: groups, types: types, my: my, player: player
    opt = parse_options(options)

    min_x = [x1, x2].min
    max_x = [x1, x2].max

    min_y = [y1, y2].min
    max_y = [y1, y2].max


    selected_vechicles = @all_vechicles.select{|k,v| (opt.player.nil? || v.player_id == opt.player.id) && (opt.types.nil? || opt.types.include?(v.type)) && (opt.groups.nil? || (opt.groups & v.groups).any? ) && v.durability > 0 && v.x >= min_x && v.x <= max_x && v.y >= min_y && v.y <= max_y }
  end

  def calculate_units_position(vechicles)
    return nil unless vechicles || vechicles.any?

    sum_x = 0
    sum_y = 0
    min_x = nil
    min_y = nil

    vechicles.each do |k, v|
      sum_x += v.x
      sum_y += v.y
      min_x = v.x if min_x.nil? || v.x < min_x
      min_y = v.y if min_y.nil? || v.y < min_y
    end

    avrg_x = sum_x / vechicles.size
    avrg_y = sum_y / vechicles.size

    width_x = 2 * (avrg_x - min_x)
    width_y = 2 * (avrg_y - min_y)

    OpenStruct.new(x: avrg_x, y: avrg_y, min_x: min_x, min_y: min_y, width_x: width_x, width_y: width_y, size: vechicles.size)
  end

  def get_reactangle_by_type(type = nil, my = true)

    group = nil
    if type && type > 5
      group = type
      type = nil
    end

    if my
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && (type.nil? || v.type == type) && (group.nil? || v.groups.include?(group)) && v.durability > 0}
    else
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && (type.nil? || v.type == type) && (group.nil? || v.groups.include?(group)) && v.durability > 0}
    end

    return OpenStruct.new(x: 0, y: 0, min_x: 0, min_y: 0, max_x: 0, max_y: 0, width_x: 0, width_y: 0, type: type || group, size: 0, durability: 0, need_healing_size: 0, speed: 0) if selected_vechicles.size == 0

    sum_x = 0
    sum_y = 0
    min_x = nil
    min_y = nil
    max_x = nil
    max_y = nil

    need_healing_size = 0
    durability = 0
    speed = 0

    selected_vechicles.each do |k, v|
      sum_x += v.x
      sum_y += v.y
      min_x = v.x if min_x.nil? || v.x < min_x
      min_y = v.y if min_y.nil? || v.y < min_y

      max_x = v.x if max_x.nil? || v.x > max_x
      max_y = v.y if max_y.nil? || v.y > max_y

      durability += v.durability

      speed += v.speed

      need_healing_size += 1 if v.durability < 79
    end

    avrg_x = sum_x / selected_vechicles.size
    avrg_y = sum_y / selected_vechicles.size

    speed = (speed / selected_vechicles.size).round(2)

    width_x = 2 * (avrg_x - min_x)
    width_y = 2 * (avrg_y - min_y)

    OpenStruct.new(x: avrg_x, y: avrg_y, min_x: min_x, min_y: min_y, max_x: max_x, max_y: max_y, width_x: width_x, width_y: width_y, type: type || group, size: selected_vechicles.size, durability: durability, need_healing_size: need_healing_size, speed: speed)


  end

  def get_right_reactangle_params_by_type(type = nil, my = true)
    if my
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && (type.nil? || v.type == type) && v.durability > 0}
    else
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && (type.nil? || v.type == type) && v.durability > 0}
    end

    vechicles = []
    selected_vechicles.each do |key, vechicle|
      vechicles << OpenStruct.new(x: vechicle.x, y:vechicle.y)
    end

    vechicles.sort! { |x,y| y.x <=> x.x }
    sum_x1 = 0
    sum_x2 = 0

    vechicles[30..39].each do |v|
      sum_x1 += v.x
    end
    vechicles[40..49].each do |v|
      sum_x2 += v.x
    end

    x1 = sum_x1 / 10
    x2 = sum_x2 / 10

    vechicles.sort! { |x,y| y.y <=> x.y }
    sum_y1 = 0
    sum_y2 = 0

    vechicles[30..39].each do |v|
      sum_y1 += v.y
    end
    vechicles[40..49].each do |v|
      sum_y2 += v.y
    end

    y1 = sum_y1 / 10
    y2 = sum_y2 / 10

    return OpenStruct.new(x1: x1, y1: y1, x2: x2, y2: y2)
  end

  def calculate_aggresive(strategy, x, y)

    my_rec = get_reactangle_by_type(strategy.group)

    selected_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && strategy.agressive_groups.include?(v.type) && v.durability > 1 && ((v.x - x)**2 + (v.y - y))**2 < 200**2 }

    aggresive_vechicles = @all_vechicles.select{|k,v|  ((v.x - x)**2 + (v.y - y))**2 < 70**2 }

    # binding.pry

    size = selected_vechicles.size

    distance = (((x - my_rec.x)**2 + (y - my_rec.y)) + 30)**2

    nearest_vechicles = selected_vechicles.select{|k,v| ((v.x - my_rec.x)**2 + (v.y - my_rec.y))**2 <= distance}

    between_size = nearest_vechicles.size

    OpenStruct.new(size: size, between_size: between_size)

  end



  def find_nearest_vehicle(x, y, type = nil, my = true)

    group = nil
    if type && type > 5
      group = type
      type = nil
    end

    if my
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && (type.nil? || v.type == type) && (group.nil? || v.groups.include?(group)) && v.durability > 0}
    else
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && (type.nil? || v.type == type) && (group.nil? || v.groups.include?(group)) && v.durability > 0}
    end

    return nil unless selected_vechicles.any?

    nearest_vechicle = selected_vechicles.first[1]
    min_dist = @world.width * @world.height

    selected_vechicles.each do |id, vechicle|
      dist = (x - vechicle.x)**2 + (y - vechicle.y)**2
      if dist <= min_dist
        min_dist = dist
        nearest_vechicle = vechicle
      end
    end

    nearest_vechicle
  end

  def nuke_profit(x, y)
    selected_vechicles = @all_vechicles.select{|k,v| v.durability > 0 && v.squared_distance_to(x, y) <= 45**2 }

    points = 0
    enemy_size = 0

    selected_vechicles.each do |id, vechicle|
      if vechicle.player_id == @me.id
        points -= (55 - vechicle.distance_to(x, y)) * 2
      else

        dist = vechicle.distance_to(x, y)
        if vechicle.durability < (110 - dist*2)
          points += 10 + vechicle.durability / 2
        else
          points += (50 - vechicle.distance_to(x, y))
        end
        enemy_size += 1
      end

    end

    OpenStruct.new(points: points, enemy_size: enemy_size)

  end

  def find_nuke_vehicle(x, y, type = nil, min_limit = 60, max_limit = 80)

    # p 'find_nuke_vehicle'

    # p 'x: ' + x.inspect
    # p 'y: ' + y.inspect
    # p 'type: ' + type.inspect
    # p 'min_limit: ' + min_limit.inspect
    # p 'max_limit: ' + max_limit.inspect

    group = nil
    if type && type > 5
      group = type
      type = nil
    end

    selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && (type.nil? || v.type == type) && (group.nil? || v.groups.include?(group)) && v.durability > 10 && v.vision_range >= min_limit && (v.x - x)**2 + (v.y - y)**2 < (max_limit + 5)**2 }

    # p 'selected: ' + selected_vechicles.size.inspect

    return nil unless selected_vechicles.any?

    nearest_vechicles = []


    min_dist = min_limit**2

    max_dist = max_limit**2

    selected_vechicles.each do |id, vechicle|
      dist = (x - vechicle.x)**2 + (y - vechicle.y)**2
      if dist >= min_dist && dist <= max_dist && (vision_factor(vechicle) * (vechicle.vision_range - 10))**2 >= dist
        nearest_vechicles << vechicle
      end
    end

    # p 'nearest ' + nearest_vechicles.size.inspect

    return nil unless nearest_vechicles.any?

    nuke_vechicle = nearest_vechicles.sort_by{|v| ( ((v.x - x)**2 + (v.y - y)**2).to_f/2).round  }.sort_by{|v| (100 - v.durability) }[0]

  end

  def find_nearest_enemy(x, y, types = nil)
    types = [0, 1, 2, 3, 4] if types.nil?

    enemies = []
    for i in types
      enemy = find_nearest_vehicle(x, y, i, false)
      enemies << enemy if enemy
    end

    return nil unless enemies.any?

    enemies.min_by{|v| v.distance_to(x,y)}

  end

  def enemy_position(types = nil)
    types = [0, 1, 2, 3, 4] if types.nil?

    res = []
    for i in types
      rec = get_reactangle_by_type(i, false)
      res << rec if rec.size > 0
    end
    res
  end

  def parse_options(options)

    groups = nil
    types = nil
    my = options[:my].nil? ? nil : options[:my]

    player = nil

    if my
      player = world.my_player
    elsif my == false
      player = world.my_player
    end

    if options[:groups]
      options[:groups].each do |group|
        if group > 5
          groups = groups.nil? ? [group] : groups << group
        else
          types = types.nil? ? [group] : types << group
        end
      end
    end

    return OpenStruct.new(groups: groups, types: types, my: my, player: player)
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
      elsif my_whether_type == WeatherType::CLOUD
        factor = 0.8
      else
        factor = 1
      end
    end

    factor
  rescue => e
    0.77
  end

  def check_stop_list(group)
    return false if @stop_list.nil?
    return true if @stop_list.group == group && @stop_list.tick > @world.tick_index

    @stop_list = nil if @stop_list.tick < @world.tick_index
    return false
  end

  # ================================================================================
  #                        MATH
  # ================================================================================

  def near_corner_coor(distance = 0)
      if @corner.x == 0
        x = distance
        y = distance
      else
        x = @world.width - distance
        y = @world.height - distance
      end

      OpenStruct.new(x: x, y: y)
  end

  def vector(angle, distance)
    radians = angle * Math::PI/180
    x = distance * Math.cos(radians)
    y = distance * Math.sin(radians)

    OpenStruct.new(x: x, y: y)
  end

  # def distance(x1, y1, x2, y2)
  #   Math.sqrt(sq_distance(x1, y1, x2, y2))
  # end

  def sqrt_distance(x1, y1, x2, y2)
    (x1-x2)**2 + (y1-y2)**2
  end

  def angle_between(x1, y1, x2, y2)
    angle_1 = (Math.atan2(x1.to_i, y1.to_i) * 180 / Math::PI).round
    angle_2 = (Math.atan2(x2.to_i, y2.to_i) * 180 / Math::PI).round

    return (angle_1 - angle_2).abs
  end


  # ================================================================================
  #                        DELAYED AND SHEDULED MOVES
  # ================================================================================

  def shedule_proc(prc, inc_tick = nil)

    if inc_tick.nil?
      tick = @world.tick_index + @sheduled_tick
    else
      tick = @world.tick_index + inc_tick
    end
    @sheduled_moves << OpenStruct.new(tick: tick, proc: prc)
  end

  def shedule(n)
    @sheduled_tick = n
  end

  def execute_delayed_move
    return nil if @me.remaining_action_cooldown_ticks > 0

    print 'D' if @debug
    @last_print = 'D'

    delay_move_info = @delayed_moves.shift
    return nil unless delay_move_info


    delay_move = delay_move_info.delayed_move


    [:action, :left, :top, :right, :bottom, :x, :y, :group, :angle, :factor, :max_speed, :max_angular_speed, :vehicle_type, :facility_id, :vehicle_id].each do |name|
      @move.send(name.to_s + '=', delay_move.send(name))
    end

    if @move.action == ActionType::DISMISS
      @selected = -5
    end

    if @move.action == ActionType::CLEAR_AND_SELECT
      if (@move.vehicle_type && @selected == @move.vehicle_type) || (@move.group > 5 && @selected == @move.group)
        p 'Alredy selected, skip'

        if @delayed_moves.any?
          execute_delayed_move
        end

        return nil
      end

      if @move.group > 5
        @selected = @move.group
      else
        @selected = @move.vehicle_type
      end
    end
  end

  def add_move(delayed_move, group = -1)
    if @sheduled_tick == 0

      # @delayed_moves << OpenStruct.new(delayed_move: delayed_move, group: group)

      if @add_before_moves
        @delayed_moves.unshift OpenStruct.new(delayed_move: delayed_move, group: group)
      else
        @delayed_moves << OpenStruct.new(delayed_move: delayed_move, group: group)
      end
    else
      tick = @world.tick_index + @sheduled_tick
      @sheduled_moves << OpenStruct.new(tick: tick, move: delayed_move, group: group)
    end
  end

  def run_strategies



    @strategies.sort{ |x,y| x.last_move <=> y.last_move }.each do |strategy|
      if strategy.run?(world.tick_index)
        if check_stop_list(strategy.group)
          p 'All strategy stopped for group : ' + strategy.group.to_s
          next
        end

        if @delayed_moves.select{|d| d.group == strategy.group}.any? && strategy.check_group
          p 'SKIP, Allready have a move group: ' + strategy.group.to_s
          next
        end

        p ''
        p ''
        p '***********************************************'
        p 'Run strategy group: ' + strategy.group.to_s + ', name: '+ strategy.f_name.to_s
        self.send(strategy.f_name, strategy)
        p ''
        p ''
      end
    end

    if @strategies_to_remove.any?
      p ''
      p '===================='
      p 'REMOVE STRATEGY'
      p @strategies.inspect
    end

    while @strategies_to_remove.any? do
      group = @strategies_to_remove.pop

      @strategies.delete_if {|strat| strat.group == group }

      if @strategies_to_remove.size  == 0
        p @strategies.inspect
      end
    end

  end

  def remove_strategy(group)
    @strategies_to_remove << group
  end

  def add_sheduled_move
    to_delete = []

    @sheduled_moves.each_index do |i|
      sheduled_move = @sheduled_moves[i]
      if @world.tick_index >= sheduled_move.tick
        if sheduled_move.proc
          sheduled_move.proc.call
        elsif sheduled_move.move
          @delayed_moves << OpenStruct.new(delayed_move: sheduled_move.move, group: sheduled_move.group)
        end

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
    if @debug
      text = "\n" + text if @last_print == 'D'
      @last_print = 'p'
      puts text
    end
  end
end
