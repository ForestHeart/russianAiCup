
module MyStratSandwitch

  GROUND_TYPE = [0, 3, 4]
  AIR_TYPE = [1, 2]

  def start_strategy_sandwitch
    if @world.tick_index == 0

      start_strategy_ground_union
    end

    if @world.tick_index == 10
      fighter_rec = get_reactangle_by_type(VehicleType::FIGHTER)
      helicopter_rec = get_reactangle_by_type(VehicleType::HELICOPTER)

      select_all(VehicleType::FIGHTER)

      set_group(14)
      set_group(15)

      x = fighter_rec.min_x
      y = fighter_rec.min_y

      select_area(x - 1, y - 1, x + 10, y + 10)
      dismiss_selected(15)

      set_group(16)


      if (fighter_rec.y - helicopter_rec.y).abs > 10
        move_by_type(300 - fighter_rec.x, 0, 14)

        @sheduled_tick = 500
        move_by_type(2500 - fighter_rec.x, 50, 16)
        @sheduled_tick = 0
      else
        move_by_type(0, 300 - fighter_rec.y, 14)

        @sheduled_tick = 500
        move_by_type(50, 2500 - fighter_rec.y, 16)
        @sheduled_tick = 0
      end

      strategy = Strategy.new('call_the_nuke', 16, 1250, 30, 0)

      strategy.check_group = false

      @strategies << strategy

      # =============== САМОЛЕТЫ  МАЛАЯ ГРУППА=======================================================
      strategy = Strategy.new('atack_nearest', 16, 1400, 30, 0)
      strategy.atack_unity_types = nil
      strategy.target_distance = 60

      strategy.second_target_distance = 60
      strategy.capture_facility = false

      strategy.no_scaling_and_rotating = true

      strategy.mod_tick_fast = 15

      strategy.nuker = true


      if @fog
        strategy.fog_x = @world.width - 50
        strategy.fog_y = @world.height - 50
      end

      @strategies << strategy



      # =============== САМОЛЕТЫ =======================================================
      strategy = Strategy.new('call_the_nuke', 15, 250, 20, 0)

      strategy.check_group = false

      @strategies << strategy

      strategy = Strategy.new('atack_nearest', 15, 200, 30, 0)
      strategy.atack_unity_types = [1, 2]
      strategy.target_distance = 7

      strategy.second_target_distance = 40
      strategy.capture_facility = false

      strategy.avoid_agressive = true
      strategy.agressive_groups = [3, 4]
      strategy.agressive_count = 10

      strategy.mod_tick_fast = 15
      strategy.mod_tick_mid = 30

      strategy.atack_rotating = true

      strategy.nuker = true
      strategy.keep_alive = true
      strategy.keep_alive_size = 20
      strategy.keep_alive_durability = 2000

      strategy.healing = true
      strategy.healing_percent = 60
      strategy.need_healing_size = 15
      strategy.need_durability = 1500

      if @fog

        strategy.target_distance = 10

        strategy.keep_alive_size = 40
        strategy.keep_alive_durability = 3000
        strategy.keep_alive_distance = 60

        strategy.fog_x = @world.width - 50
        strategy.fog_y = @world.height - 50
      end

      @strategies << strategy
    end

    if @world.tick_index == 250


      select_all(VehicleType::HELICOPTER)
      # Делаем группу вертолетов
      set_group(13)
    end

    if @world.tick_index == 700
      # Отправляем в центр танков

        tank_rec = get_reactangle_by_type(VehicleType::TANK)
        air_rec = get_reactangle_by_type(13)
        move_by_type(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 13)
    end

    if @world.tick_index == 1000
      select_all(0)
      add_to_select(2)
      add_to_select(3)
      add_to_select(4)
      set_group(10)

      # puts 'Stratagy atack_nearest added'
    end

    if @world.tick_index == 1100

      # ========================== БУТЕРБРОД =======================================================
      strategy = Strategy.new('atack_nearest', 10, 1450, 30, 0, 0.18)
      strategy.atack_unity_types = [0,3,4]
      strategy.second_target_distance = 12
      strategy.compacting_k = 12

      strategy.keep_alive = true
      strategy.keep_alive_size = 30
      strategy.keep_alive_durability = 2500
      strategy.keep_alive_distance = 20

      if @fog

        strategy.keep_alive_size = 40
        strategy.keep_alive_durability = 3000
        strategy.keep_alive_distance = 60

        strategy.fog_x = @world.width - 50
        strategy.fog_y = @world.height - 50
      end

      @strategies << strategy


      if @world.facilities.size > 2
        # Делим бутерброд

        my_rec = get_reactangle_by_type(10)

        select_area(my_rec.x + my_rec.width_x / 5 , my_rec.min_y - 5, my_rec.max_x + 5, my_rec.max_y + 5)
        deselect_all(VehicleType::FIGHTER)
        dismiss_selected(10)
        set_group(9)

        select_area(my_rec.min_x - 5 , my_rec.y + my_rec.width_y / 5, my_rec.x + my_rec.width_x / 5 - 0.1, my_rec.max_y + 5)
        deselect_all(VehicleType::FIGHTER)
        dismiss_selected(10)
        set_group(8)
      end
    end

    if @world.tick_index == 1270 && @world.facilities.size > 2

      selected_facilities = @world.facilities.select{ |f| f.owner_player_id != @me.id}

      target_facilities = []

      # Ближний к углу
      my_x = 0; my_y = 0
      nearest_facility = selected_facilities.min_by{|f| ((f.left + 32 - my_x)**2 + (f.top + 32 - my_y)**2) }
      target_facilities << nearest_facility.id

      min_ticks = []

      my_xs = []
      my_ys = []

      # Правый верхний угол
      my_xs[9] = @world.width / 2 + 100; my_ys[9] = 50
      my_xs[8] = 50; my_ys[8] = @world.height / 2 + 100

      for i in [8,9]

        my_x = my_xs[i]; my_y = my_ys[i];


        selected_facilities = selected_facilities.select{ |f| !target_facilities.include?(f.id)}
        nearest_facility = selected_facilities.min_by{|f| ((f.left + 32 - my_x)**2 + (f.top + 32 - my_y)**2) }

        @sheduled_tick = 0

        scale_from_center_by_type(0.8, i)

        @sheduled_tick = 20

        if nearest_facility
          target_facilities << nearest_facility.id
          move_to_by_type(nearest_facility.left + 32, nearest_facility.top + 32, i, 0.2)

          my_rec = get_reactangle_by_type(i)
          min_ticks[i] = Math::hypot(my_rec.x - nearest_facility.left + 32, my_rec.y - nearest_facility.top + 32) / 0.2
        else
          move_by_type(my_x, my_y, i, 0.2)
          min_ticks[i] = Math::hypot(my_x, my_y) / 0.2
        end

         # ========================== БУТЕРБРОД =======================================================
        strategy = Strategy.new('atack_nearest', i, 1300 + min_ticks[i], 30, 0, 0.18)
        strategy.atack_unity_types = [0,3,4]
        strategy.second_target_distance = 12
        strategy.compacting_k = 10

        strategy.keep_alive = true
        strategy.keep_alive_size = 15
        strategy.keep_alive_durability = 3000
        strategy.keep_alive_distance = 30

        if @fog

          strategy.fog_x = @world.width - 50
          strategy.fog_y = @world.height - 50
        end

        @strategies << strategy
      end
      @sheduled_tick = 0

    end

  end

  def start_strategy_ground_union
    recs = {}

    first = 0
    second = 3
    third = 4

    for i in GROUND_TYPE
      recs[i] = get_reactangle_by_type(i)
    end

    dist_0_3 = sqrt_distance(recs[0].x, recs[0].y, recs[3].x, recs[3].y)
    dist_0_4 = sqrt_distance(recs[0].x, recs[0].y, recs[4].x, recs[4].y)
    dist_3_4 = sqrt_distance(recs[3].x, recs[3].y, recs[4].x, recs[4].y)


    if dist_0_4 <= dist_0_3 && dist_0_4 <= dist_3_4
      first = 0
      second = 4
      third = 3
    elsif dist_0_3 <= dist_0_4 && dist_0_3 <= dist_3_4
      first = 0
      second = 3
      third = 4
    elsif dist_3_4 <= dist_0_3 && dist_3_4 <= dist_0_4
      first = 3
      second = 4
      third = 0
    end

    if @corner.x == 0
      move_by_type(5, 5, nil)
    else
      move_by_type(-5, -5, nil)
    end

    @sheduled_tick = 50

    st1_union_2_groups(first, second)
    @sheduled_tick = 0

    scale_from_center_by_type(0.8, third)

    st1_move_forward_third(first, second, third)

    # @sheduled_tick = 50
    # st1_union_2_groups(1, 2)

    # x = @world.width / 2.0
    # y = @world.height / 2.0
    # move_to_by_type(x, y, 1)
    # move_to_by_type(x, y, 2)

  end

  def st1_wait_part_3(first, second, third)

    if @st_1.part_1 == true && @st_1.part_2 == true
      prc = Proc.new do
        st1_get_final_one(first, second, third)
      end
      shedule_proc(prc)
    else
      prc = Proc.new do
        st1_wait_part_3(first, second, third)
      end
      shedule_proc(prc, 30)
    end

  end

  #  Двигаем третью группу в точку объединения
  def st1_move_forward_third(first, second, third)
    first_rec = get_reactangle_by_type(first)
    second_rec = get_reactangle_by_type(second)
    third_rec = get_reactangle_by_type(third)

    shift_move = second_rec.width_x * 1.8
    shift_move = -shift_move if @corner.x != 0

    p 'shift_move: ' + shift_move.to_s

    group_x = (first_rec.x + second_rec.x) / 2
    group_y = (first_rec.y + second_rec.y) / 2

    @sheduled_tick = 30
    @sheduled_tick += 30 if VehicleType::TANK == third

    # Слегка отодвигаем чтобы не помешать двум наземным группам

    shift_x = group_x > third_rec.x ? -2 : 2
    shift_y = group_y > third_rec.y ? -2 : 2
    move_by_type(shift_x, shift_y, third)
    @sheduled_tick += 100
    @sheduled_tick += 30 if VehicleType::TANK == third

    # Определяем точку, куда предварительно двигаем группу для объединения
    points_to = []
    points_to << OpenStruct.new(x: group_x - shift_move, y: group_y) if group_x > shift_move*1.5
    points_to << OpenStruct.new(x: group_x, y: group_y - shift_move) if group_y > shift_move*1.5
    points_to << OpenStruct.new(x: group_x, y: group_y + shift_move)
    points_to << OpenStruct.new(x: group_x + shift_move, y: group_y)

    p 'Near point for third: ' + points_to.inspect

    nearest_poin = points_to[0]
    nearest_dist = (points_to[0].x - third_rec.x)**2 + (points_to[0].y - third_rec.y)**2

    points_to.each do |point|
      new_point_distance = (point.x - third_rec.x)**2 + (point.y - third_rec.y)**2

      if new_point_distance < nearest_dist
        nearest_poin = point
        nearest_dist = new_point_distance
      end
    end

    # точка куда двигать
    move_to_x = nearest_poin.x
    move_to_y = nearest_poin.y

    third_rec = get_reactangle_by_type(third)

    if move_to_x > third_rec.x
      add_x = third_rec.width_x
    else
      add_x = -third_rec.width_x
    end

    move_to_x_units_count = get_units(third_rec.x, move_to_x + add_x, third_rec.min_y - 5, third_rec.max_y + 5, {groups: [first, second], my: true}).size

    if move_to_x_units_count > 0
      @sheduled_tick += 60
    end

    # get_units(x1, y1, x2, y2, options={})

    @sheduled_tick += 30
    @sheduled_tick += 20 if VehicleType::TANK == third

    # двигаем по оси x
    move_to_by_type(move_to_x, third_rec.y, third)

    @sheduled_tick += (move_to_x - third_rec.x).abs*2.8 + 80
    @sheduled_tick += 20 if VehicleType::TANK == third

    # двигаем по оси y
    move_to_by_type(third_rec.x, move_to_y, third)

    @sheduled_tick += (move_to_y - third_rec.y).abs*2.8 + 80
    @sheduled_tick += 20 if VehicleType::TANK == third

    # Расшираяемся до размеров первых двух объектов
    prc = Proc.new do
      scale_from_center_by_type(1.9111, third)
    end
    shedule_proc(prc)

    @sheduled_tick += 130

    # Готовы к объединению
    prc = Proc.new do
      @st_1.part_2 = true
      st1_wait_part_3(first, second, third)
    end
    shedule_proc(prc)

    @sheduled_tick = 0
  end

  def st1_union_2_groups(first, second)

    first_rec = get_reactangle_by_type(first)
    second_rec = get_reactangle_by_type(second)

    # p first_rec.inspect
    # p second_rec.inspect

    # if (first_rec.x - second_rec.x)

    x = (first_rec.x + second_rec.x) / 2
    y = (first_rec.y + second_rec.y) / 2

    x1 = (x + first_rec.x*2) / 3
    y1 = (y + first_rec.y*2) / 3

    x2 = (x + second_rec.x*2) / 3
    y2 = (y + second_rec.y*2) / 3

    scale_from_x_y_by_type(x1, y1, 1.52, first)
    scale_from_x_y_by_type(x2, y2, 1.52, second)

    next_tick = 170

    if @corner.x == 0
      shift_move = 2
    else
      shift_move = -2
    end

    move_x = (first_rec.x - second_rec.x).abs > 10
    move_y = (first_rec.y - second_rec.y).abs > 10

    @sheduled_tick += next_tick

    if move_x
      # Первое мелкое движение
      unless move_y
        move_by_type(0, shift_move*2, first)
        @sheduled_tick += 30
      else
        move_by_type(shift_move*2, 0, first)
        @sheduled_tick += 30
      end

      move_by_type((second_rec.x - first_rec.x)*0.65, 0, first)
      move_by_type((first_rec.x - second_rec.x)*0.48 + shift_move, 0, second)

      next_tick = 250

      if move_y
        @sheduled_tick += next_tick

        prc = Proc.new do
          st1_check_union_by_axis(first, second, :x)
        end
        shedule_proc(prc)
        @sheduled_tick += 30

        move_by_type(0, (second_rec.y - first_rec.y)*0.65, first)
        move_by_type(0, (first_rec.y - second_rec.y)*0.48, second)

        next_tick = 150
      end
    else
      if move_x
        move_by_type(0, shift_move*2, first)
        @sheduled_tick += 20
      else
        move_by_type(shift_move*2, 0, first)
        @sheduled_tick += 20
      end

      move_by_type(0, (second_rec.y - first_rec.y)*0.65, first)
      move_by_type(0, (first_rec.y - second_rec.y)*0.48 + shift_move, second)

      next_tick = 250

      if move_x
        @sheduled_tick += next_tick

        prc = Proc.new do
          st1_check_union_by_axis(first, second, :y)
        end
        shedule_proc(prc)
        @sheduled_tick += 30

        move_by_type((second_rec.x - first_rec.x)*0.65, 0, first)
        move_by_type((first_rec.x - second_rec.x)*0.48, 0, second, 30)

        next_tick = 150
      end
    end

    @sheduled_tick += next_tick
    prc = Proc.new do
      @st_1.part_1 = true
    end
    shedule_proc(prc)

    @sheduled_tick = 0

  end

  def st1_check_union_by_axis(first, second, axis = :x, in_line = false, max_dist = 10)
    p 'st1_check_union_by_axis axis: ' + axis.to_s

    point1 = get_right_reactangle_params_by_type(first)
    point2 = get_right_reactangle_params_by_type(second)

    # p point1.inspect
    # p point2.inspect

    wide = (point2.send(axis.to_s + '1') - point2.send(axis.to_s + '2')).abs

    if in_line
      dist = point2.send(axis.to_s + '1') - point1.send(axis.to_s + '1')
    else
      dist1 = (point2.send(axis.to_s + '1') + point2.send(axis.to_s + '2')) / 2 - point1.send(axis.to_s + '1')
      dist2 = (point2.send(axis.to_s + '1') + point2.send(axis.to_s + '2')) / 2 - point1.send(axis.to_s + '2')

      if dist1.abs < dist2.abs
        dist = dist1
      else
        dist = dist2
      end
    end

    while dist.abs > max_dist do
      if dist > 0
        dist -= wide
      else
        dist += wide
      end
    end

    p 'dist: ' + dist.inspect
    return false if dist > max_dist

    if axis.to_s == 'x'
      x = dist
      y = 0
    else
      x = 0
      y = dist
    end

    move_by_type(x, y, first)
    return dist
  end

  def st1_get_final_one(first, second, third)
    first_rec = get_reactangle_by_type(first)
    second_rec = get_reactangle_by_type(second)
    third_rec = get_reactangle_by_type(third)

    # p get_right_reactangle_params_by_type(first).inspect
    # p get_right_reactangle_params_by_type(second).inspect
    # p get_right_reactangle_params_by_type(third).inspect

    if (third_rec.x - first_rec.x).abs > (third_rec.y - first_rec.y).abs
      axis = :y
      rt_axis = :x
    else
      axis = :x
      rt_axis = :y
    end

    st1_check_union_by_axis(first, second, rt_axis)
    @sheduled_tick += 30
    st1_check_union_by_axis(first, second, axis, true)
    st1_check_union_by_axis(third, second, axis)

    # st1_check_union_by_axis(first, second, rt_axis, false, 5)
    # @sheduled_tick += 30
    # st1_check_union_by_axis(first, second, axis, true, 5)
    # st1_check_union_by_axis(third, second, axis, 12)

    @sheduled_tick += 50

    if (third_rec.x - first_rec.x).abs > (third_rec.y - first_rec.y).abs
      move_by_type((first_rec.x - third_rec.x), 0, third)
    else
      move_by_type(0, (first_rec.y - third_rec.y), third)
    end

    @sheduled_tick += 250

    prc = Proc.new do

      select_all(VehicleType::HELICOPTER)

      tank_rec = get_reactangle_by_type(VehicleType::IFV)
      air_rec = get_reactangle_by_type(VehicleType::HELICOPTER)
      move_selected(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 0.7)
    end
    shedule_proc(prc)


    @sheduled_tick += 200

    if @world.facilities.size < 1
      prc = Proc.new do
        tank_rec = get_reactangle_by_type(VehicleType::TANK)
        scale_from_x_y_by_type(tank_rec.x, tank_rec.y, 0.2, 10, 0.4)
      end
      shedule_proc(prc)
      @sheduled_tick += 60
    end


    prc = Proc.new do

      select_all(VehicleType::HELICOPTER)

      tank_rec = get_reactangle_by_type(VehicleType::IFV)
      air_rec = get_reactangle_by_type(VehicleType::HELICOPTER)
      move_selected(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 0.7)
    end
    shedule_proc(prc)

    @sheduled_tick += 30

    # prc = Proc.new do
    #   tank_rec = get_reactangle_by_type(VehicleType::TANK)
    #   rotate_from_x_y_by_type(tank_rec.x, tank_rec.y, Math::PI * 45 / 180, 0.2)
    # end
    # shedule_proc(prc)


    # @sheduled_tick += 250

    if @world.facilities.size < 1
      prc = Proc.new do
        tank_rec = get_reactangle_by_type(VehicleType::TANK)
        scale_from_x_y_by_type(tank_rec.x, tank_rec.y, 0.5, 10, 0.3)
      end
      shedule_proc(prc)
    end

    @sheduled_tick = 0

  end
end
