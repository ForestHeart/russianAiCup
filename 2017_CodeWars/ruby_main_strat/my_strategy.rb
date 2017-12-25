require './model/game'
require './model/move'
require './model/player'
require './model/world'
require 'ostruct'

require './my_classes'
require './my_actions'
require './my_helper'
require './my_strat_sandwitch'
require './my_strat_fast'
require './my_strat_nuclear'
require './my_strat_atack'
require './strategy'

# require 'pry'

class MyStrategy

  include MyActions
  include MyHelper
  include MyStratSandwitch
  include MyStratFast
  include MyStratNuclear
  include MyStratAtack

  attr_accessor :sheduled_tick
  attr_accessor :delayed_moves
  attr_accessor :sheduled_moves
  attr_accessor :move
  attr_accessor :world
  attr_accessor :me
  attr_accessor :all_vechicles

  attr_accessor :corner
  attr_accessor :angle

  attr_accessor :st_1

  GROUND_TYPE = [0, 3, 4]
  AIR_TYPE = [1, 2]


  def initialize
    @debug = false

    @fog = false

    @pp_size = 32
    @pp_min_group = 1

    @facility_prod_counts = 25
    @global_facility_distance_k = 10

    @add_before_moves = false

    @kover = false

    @nuke_avoiding = false

    @total_time = 0.to_f

    @stop_list = nil

    @selected = -1
    @last_print = 'p'
    @delayed_moves = []
    @sheduled_tick = 0
    @sheduled_moves = []
    @strategies = []

    @strategies_to_remove = []

    @all_vechicles = {}
    @corner = OpenStruct.new(x: 0, y: 0)

    @st_1 = OpenStruct.new(part_1: false, part_2: false)

    p 'MyStrategy intialized'
  end

  # @param [Player] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def init(me, world, game, move)
    @move = move
    @world = world
    @me = me

    update_all_vechicles

    if world.tick_index == 0

      p 'SEED: ' + game.random_seed.to_s

      world.new_vehicles.each do |vechicle|
        @all_vechicles[vechicle.id] = vechicle
      end

      if enemy_position.size == 0
        @fog = true
        # binding.pry
      end

      vechicle = find_first_own_vechicle

      if vechicle.x  > @world.width / 2.0
        @corner.x = @world.width
        @corner.y = @world.height
      end

    end
  end

  # @param [Player] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    start_time = Time.now

    shedule 0
    init(me, world, game, move)

    start_strategy_sandwitch
    # start_strategy_fast

    if world.tick_index == 10
      @strategies << Strategy.new('call_the_nuke', nil, 20, 20, 3)
      # puts 'Stratagy call_the_nuke added'


      # for i in 0..4 do
      #   select_all(i)
      #   set_group(10 + i)

      #   strategy = Strategy.new('atack_nearest', 10 + i, 50, 30, i*5)

      #   # air
      #   if [1,2].include?(i)
      #     strategy.capture_facility = false
      #     strategy.target_distance = 0
      #     strategy.atack_unity_types = [1,2] if i == 1

      #     strategy.atack_unity_types = [0,2,4] if i == 2
      #   end

      #   @strategies << strategy
      # end

    end

    if @delayed_moves.any?
      execute_delayed_move
    end

    if @sheduled_moves.any?
      add_sheduled_move
    end


    if @me.remaining_action_cooldown_ticks == 0
      run_strategies if @strategies.any?

      avoid_nuke if world.tick_index > 400

    end

    if world.tick_index % 100 == 0 && world.tick_index > 1300
      start_facilities
    end

    if world.tick_index % 50 == 0
      p ''
      p '============='
      p 'moves size: ' + @delayed_moves.size.to_s
      # p @delayed_moves.inspect
      p ''
    end

    if world.tick_index % 200 == 0

      check_kover if world.tick_index < 2000 && @kover == false && !@fog

      p 'Total time on ' + world.tick_index.to_s + ' is ' + @total_time.to_s
    end

    @total_time += Time.now - start_time
  rescue => e
    puts '================================================================================='
    puts "An error of type #{e.class} happened, message is #{e.message}"
    puts '================================================================================='

    if @debug
      raise e
    end
  end

  def start_facilities
    return nil if @world.facilities.size < 1

    my_facilities = @world.facilities.select{ |f| f.owner_player_id == @me.id && f.type == 1}

    if my_facilities.size < 2
      @global_facility_distance_k = 10
    else
      @global_facility_distance_k = 1
    end

    my_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 1}
    enemy_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && v.durability > 1}


    # =============== Set up production  ========================
    if (my_vechicles.size > enemy_vechicles.size * 3 && !@fog) || (@fog && my_vechicles.size > 700)
      my_facilities.each do |facility|
        if facility.vehicle_type != nil

          set_facility_production(facility, nil)
          # puts 'stop facility prod'
        end
      end
    else
      my_facilities.each do |facility|
        if facility.vehicle_type == nil

          facility_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.x < facility.left + 64 && v.x > facility.left && v.y < facility.top + 64 && v.y > facility.top}
          grouped_facility_vechicles = facility_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 1 && v.groups.any?}

          production_type = get_production_type

          set_facility_production(facility, production_type) if grouped_facility_vechicles.size < 5
          # puts 'start facility prod'
        end
      end
    end


    # =============== Assign vechicles  ========================
    my_facilities.each do |f|
      facility_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.x < f.left + 64 && v.x > f.left && v.y < f.top + 64 && v.y > f.top}

      @facility_prod_counts = 30 if @strategies.count > 5
      @facility_prod_counts = 50 if @strategies.count > 10
      @facility_prod_counts = 80 if @strategies.count > 15

      # binding.pry

      # my group vechicles here
      grouped_facility_vechicles = facility_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.groups.any?}
      new_facility_vechicles = facility_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.groups.size.zero?}

      assigned_group_ids = grouped_facility_vechicles.map{|k,v| v.groups}.flatten.uniq

      group_id = get_max_group_id + 1

      if f.vehicle_type == nil && new_facility_vechicles.size > 0

        select_facility(f)

        assigned_group_ids.each do |assigned_group_id|
          dismiss_selected(assigned_group_id)
        end

        set_group(group_id)
        scale_from_x_y_by_type(f.left + 32, f.top + 32, 0.4, group_id)

        strategy = Strategy.new('atack_nearest', group_id, world.tick_index + 2, 30, 0)

        set_strategy_tactic(strategy, f)

        @strategies << strategy

        group_id += 1
      elsif new_facility_vechicles.size > grouped_facility_vechicles.size + @facility_prod_counts
        set_facility_production(f, nil)

        select_facility(f)

        assigned_group_ids.each do |assigned_group_id|
          dismiss_selected(assigned_group_id)
        end

        set_group(group_id)
        @sheduled_tick = 1
        scale_from_x_y_by_type(f.left + 32, f.top + 32, 0.4, group_id)

        strategy = Strategy.new('atack_nearest', group_id, world.tick_index + 2, 30, 0)
        set_strategy_tactic(strategy, f)
        @strategies << strategy

        group_id += 1

        @sheduled_tick = 250
        set_facility_production(f, get_production_type)
        @sheduled_tick = 0
      end

    end
  end

  def get_production_type
    enemies = []
    allies = []

    # ARRV = 0
    # FIGHTER = 1
    # HELICOPTER = 2
    # IFV = 3
    # TANK = 4

    for i in 0..4
      enemies[i] = get_reactangle_by_type(i, false).size
      allies[i] = get_reactangle_by_type(i, true).size
    end

    air_enemies = enemies[1] + enemies[2]
    air_allies = allies[1] + allies[2]

    # binding.pry

    if @fog
      return 1 if allies[1] < 15

      return 4
    end

    # Делаем самолеты
    if air_enemies > 50 && air_enemies > air_allies * 2 && air_allies < 50
      # если много вертолетов, делаем бтр и самолеты
      return [1, 3].sample if enemies[2] > enemies[1] * 2
      return 1
    end

    # против танков делаем танки и вертолеты
    if enemies[4] > 150 && ( enemies[4] > enemies[0] + enemies[1] + enemies[2] + enemies[3])
      return [2,4].sample
    end

    # против наземки Без пво делаем танки и вертолеты
    if enemies[1] + enemies[2] + enemies[3] < 10
      return [2, 4].sample
    end


    # против наземки делаем танки
    if enemies[1] + enemies[2] < 30
      return 4
    end

    # Иначе бтр с танками
    return 4

  end


  def set_strategy_tactic(strategy, facility)
    # ARRV = 0
    # FIGHTER = 1
    # HELICOPTER = 2
    # IFV = 3
    # TANK = 4

    type = facility.vehicle_type
    if facility.vehicle_type
      type = @all_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.x < facility.left + 64 && v.x > facility.left && v.y < facility.top + 64 && v.y > facility.top}.to_a.first[1].type

      # binding.pry

    end

    set_strategy_by_type(strategy, type)

  end

  def set_strategy_by_type(strategy, type)

    # самолеты
    if type == 1
      strategy.atack_unity_types = [1, 2]
      strategy.target_distance = 10

      strategy.second_target_distance = 40
      strategy.capture_facility = false

      strategy.avoid_agressive = true
      strategy.agressive_groups = [3, 4]
      strategy.agressive_count = 10

      strategy.atack_rotating = true

      strategy.nuker = true
      strategy.keep_alive = true
      strategy.keep_alive_size = 5
      strategy.keep_alive_durability = 500
    end

    # вертолеты
    if type == 2
      strategy.atack_unity_types = [0, 2, 4]
      strategy.target_distance = 10

      strategy.second_target_distance = 40
      strategy.capture_facility = false

      strategy.avoid_agressive = true
      strategy.agressive_groups = [1, 3]
      strategy.agressive_count = 5

      strategy.atack_rotating = true

      strategy.nuker = true
    end

    # ПВО
    if type == 3
      strategy.atack_unity_types = [1, 2]
      strategy.target_distance = 10

      strategy.second_target_distance = 40
      strategy.capture_facility = true
      strategy.facility_distance_k = 7

      strategy.avoid_agressive = true
      strategy.agressive_groups = [4]
      strategy.agressive_count = 10
    end

    # ТАНК
    if type == 4
      strategy.atack_unity_types = [0, 3, 4]
      strategy.target_distance = 10

      strategy.second_target_distance = 15
      strategy.capture_facility = true
      strategy.facility_distance_k = 5

      strategy.keep_alive = true
      strategy.keep_alive_size = 5
      strategy.keep_alive_durability = 500
    end
  end

  def check_kover

    n = (@world.width / @pp_size)
    m = (@world.height / @pp_size)

    @pp = []
    @active_pp = []

    awesome_print @pp

    for x in 0..n
      @pp[x] = []
      for y in 0..m
        @pp[x][y] = nil
      end
    end

    @all_vechicles.each do |id, vechicle|
      next if vechicle.durability < 0.1 || vechicle.player_id == @me.id

      n = vechicle.x.to_i / @pp_size
      m = vechicle.y.to_i / @pp_size

      pole = @pp[n][m]

      unless pole
        pole = OpenStruct.new(
          allies: 0,
          enemies: 0,
          enemy_types: {0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0},
          ally_types: {0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0},
          enemy_ids: [],
          n: nil,
          m: nil,
          group: nil
        )

        @pp[n][m] = pole

        # p 'Assign pole n: ' + n.to_s + ' m: ' + m.to_s
      end

      pole.n = n unless pole.n
      pole.m = m unless pole.m

      if vechicle.player_id == @me.id
        pole.allies += 1
        pole.ally_types[vechicle.type.to_i] += 1
      else
        pole.enemies += 1
        pole.enemy_types[vechicle.type.to_i] += 1
        pole.enemy_ids << id
      end

    end

    @pp.flatten.each do |pole|
      if pole
        @active_pp << pole
      end
    end

    if @debug
      p 'PP:'
      awesome_print @active_pp

      all_size = (@world.width / @pp_size)**2

      p 'percent: ' + ((@active_pp.size.to_f / all_size)*100).to_s
    end

    all_size = (@world.width / @pp_size)**2

    activate_kover if ((@active_pp.size.to_f / all_size)*100) > 12
  end

  def activate_kover
    @kover = true
    # binding.pry

    @strategies.each do |strategy|
      strategy.target_distance = 1
      strategy.avoid_agressive = false
      if strategy.f_name == 'call_the_nuke'
        strategy.mod_tick = 200
      end
    end

    scale_from_center_by_type(1.5, 15)

    prc = Proc.new do
      select_all(VehicleType::HELICOPTER)

      grouped_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && v.durability > 0 && v.type == VehicleType::HELICOPTER}

      assigned_group_ids = grouped_vechicles.map{|k,v| v.groups}.flatten.uniq

      assigned_group_ids.each do |assigned_group_id|
        dismiss_selected(assigned_group_id)
      end

      set_group(7)

      # =============== САМОЛЕТЫ
      strategy = Strategy.new('atack_nearest', 7, 1700, 30, 0)
      strategy.atack_unity_types = [0, 2, 4]
      strategy.target_distance = 3

      strategy.second_target_distance = 40
      strategy.capture_facility = false

      strategy.avoid_agressive = false
      strategy.agressive_groups = [3]
      strategy.agressive_count = 10

      @strategies << strategy

      scale_from_center_by_type(1.5, 7)

    end
    shedule_proc(prc, 2000 - @world.tick_index)





  end

  def get_max_group_id
    id = 20
    @strategies.each do |s|
      id = s.group.to_i if s.group.to_i > id
    end

    id
  end

end
