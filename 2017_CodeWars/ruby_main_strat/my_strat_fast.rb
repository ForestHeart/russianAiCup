
module MyStratFast

  GROUND_TYPE = [0, 3, 4]
  AIR_TYPE = [1, 2]

  def start_strategy_fast
    if @world.tick_index == 1

      fighter_rec = get_reactangle_by_type(VehicleType::FIGHTER)
      helicopter_rec = get_reactangle_by_type(VehicleType::HELICOPTER)

      select_all(VehicleType::HELICOPTER)
      helic_group_id = 11
      set_group(helic_group_id)

      # scale_from_center_by_type(0.5, VehicleType::FIGHTER, 0.5)

      select_all(VehicleType::FIGHTER)
      set_group(13)

      x = fighter_rec.min_x
      y = fighter_rec.min_y

      select_area(x - 1, y - 1, x + 10, y + 10)
      dismiss_selected(13)
      set_group(12)

      # scale_from_center_by_type(0.5, VehicleType::HELICOPTER, 0.5)


      if helicopter_rec.x >= fighter_rec.x && helicopter_rec.y >= fighter_rec.y

        @sheduled_tick = 10
        if helicopter_rec.x > fighter_rec.x
          move_by_type(200, 0, 11)
        else
          move_by_type(0, 200, 11)
        end

        @sheduled_tick = 50
        go_air(fighter_rec)
        go_helic(helic_group_id)
        @sheduled_tick = 0

      else
        @sheduled_tick = 50
        go_air(fighter_rec)
        go_helic(helic_group_id)
        @sheduled_tick = 0
      end



    end


    if world.tick_index == 2

      random = Random.new

      # puts start_position.inspect

      for i in [0,3,4]


        scale_from_center_by_type(2, i)


        # puts (get_reactangle_by_type(i).min_x / 70 + 1).to_i
        # rotate_from_center_by_type(random.rand - 0.5, nil, i)
      end

    end

    if world.tick_index == 90

      select_all(0)
      add_to_select(3)
      add_to_select(4)
      set_group(7)
    end


    # for i in (0..10)

    #   if @world.tick_index == 100 * i + 100

    #     p 'rotate'
    #     p @world.tick_index.to_s
    #     rotate_from_center_by_type(1.7, nil, 7)
    #   end

    #   if @world.tick_index == 100 * i + 150
    #     p 'scale'
    #     p @world.tick_index.to_s
    #     scale_from_center_by_type(0.1, 7)
    #   end
    # end

  end

  def go_air(fighter_rec)


    # =============== САМОЛЕТЫ =======================================================
    strategy = Strategy.new('call_the_nuke', 13, @sheduled_tick + 55, 20, 0)

    strategy.check_group = false

    @strategies << strategy

    strategy = Strategy.new('atack_nearest', 13, @sheduled_tick + 25, 30, 0)
    strategy.atack_unity_types = [1, 2]
    strategy.target_distance = 2

    strategy.second_target_distance = 50
    strategy.capture_facility = false

    strategy.avoid_agressive = true
    strategy.agressive_groups = [3, 4]
    strategy.agressive_count = 10

    strategy.mod_tick_fast = 15
    strategy.mod_tick_mid = 30

    strategy.atack_rotating = true

    strategy.nuker = true
    strategy.keep_alive = true
    strategy.keep_alive_size = 10
    strategy.keep_alive_durability = 2000

    strategy.healing = true
    strategy.healing_percent = 50
    strategy.need_healing_size = 25
    strategy.need_durability = 2500

    if @fog
      strategy.keep_alive_size = 20
      strategy.keep_alive_durability = 3000
      strategy.keep_alive_distance = 50

      strategy.fog_x = @world.width - 50
      strategy.fog_y = @world.height - 50
    end

    @strategies << strategy
  end


  def go_helic(helic_group_id)

    # =============== Вертолеты =======================================================
    strategy = Strategy.new('call_the_nuke', helic_group_id, @sheduled_tick + 555, 20, 0)

    strategy.check_group = false

    @strategies << strategy

    strategy = Strategy.new('atack_nearest', helic_group_id, @sheduled_tick + 525, 30, 0)

    strategy.atack_unity_types = [0, 2, 4]
    strategy.target_distance = 5

    strategy.second_target_distance = 50
    strategy.capture_facility = false

    strategy.avoid_agressive = true
    strategy.agressive_groups = [1, 3]
    strategy.agressive_count = 5

    strategy.atack_rotating = true

    strategy.nuker = true

    strategy.healing = true
    strategy.healing_percent = 50
    strategy.need_healing_size = 25
    strategy.need_durability = 2500

    if @fog
      strategy.keep_alive_size = 20
      strategy.keep_alive_durability = 3000
      strategy.keep_alive_distance = 50

      strategy.fog_x = @world.width - 50
      strategy.fog_y = @world.height - 50
    end

    @strategies << strategy
  end


end
