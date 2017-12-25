require './model/game'
require './model/move'
require './model/player'
require './model/world'
require 'ostruct'

class MyStrategy

  DEBUG = false

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
    @selected = -1
    @last_print = 'p'
    @delayed_moves = []
    @sheduled_tick = 0
    @sheduled_moves = []
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

      vechicle = find_first_own_vechicle

      if vechicle.x  > @world.width / 2.0
        @corner.x = @world.width
        @corner.y = @world.height
      end

      @angle = Math.atan2(@world.width / 2.0 - @corner.x, @world.height / 2.0 - @corner.y) * 180 / Math::PI

    end
  end

  # @param [Player] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    shedule 0
    init(me, world, game, move)

    # if me.remaining_nuclear_strike_cooldown_ticks < 1 && me.next_nuclear_strike_vehicle_id < 1
    #   p ''
    #   p 'NUCLEAR INIT'
    #   p me.inspect
    #   nuclear_strike
    # end

    start_strategy_sandwitch

    # if world.tick_index > 1000 && (world.tick_index%2000) == 0
    #   rec = enemy_position.max_by(&:size)
    #   move_to_by_type(rec.x, rec.y, nil, 0.3)
    #   p 'update move'
    # end


    if @delayed_moves.any?
      execute_delayed_move
    end

    if @sheduled_moves.any?
      add_sheduled_move
    end
  end

  # ====================================================================================================================================
  # ====================================================================================================================================
  # ====================================================================================================================================

  def start_strategy_sandwitch
    if world.tick_index == 0

      start_strategy_ground_union
    end

    if world.tick_index == 100

      @sheduled_tick = 30
      st1_union_2_groups(VehicleType::FIGHTER, VehicleType::HELICOPTER)

      @sheduled_tick += 130
      p 'sheduled assign air group to ' + @sheduled_tick.to_s
      select_all(VehicleType::FIGHTER)

      add_to_select(VehicleType::HELICOPTER)

      # Делаем группу вертолетов
      set_group(77)

      # Отправляем в центр танков
      prc = Proc.new do

        select_all(77)

        tank_rec = get_reactangle_by_type(VehicleType::TANK)
        air_rec = get_reactangle_by_type(VehicleType::FIGHTER)
        move_selected(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 0.7)
      end
      shedule_proc(prc)

      @sheduled_tick += 50
      prc = Proc.new do

        select_all(77)

        tank_rec = get_reactangle_by_type(VehicleType::TANK)
        air_rec = get_reactangle_by_type(VehicleType::FIGHTER)
        move_selected(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 0.7)
      end
      shedule_proc(prc)

    end

    if world.tick_index > 1400 && (world.tick_index%200) == 0
      rec = enemy_position.max_by(&:size)
      move_to_by_type(rec.x, rec.y, nil, 0.18)
      puts 'update move'
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

    @sheduled_tick = 30

    st1_union_2_groups(first, second)
    @sheduled_tick = 0

    scale_from_center_by_type(0.8, third)

    st1_move_forward_third(first, second, third)

    @sheduled_tick = 50
    # st1_union_2_groups(1, 2)

    # x = @world.width / 2.0
    # y = @world.height / 2.0
    # move_to_by_type(x, y, 1)
    # move_to_by_type(x, y, 2)

  end

  def st1_wait_part_3(first, second, third)

    if @st_1.part_1 == true && @st_1.part_2 == true
      prc = Proc.new do
        st1_trhee_in_one(first, second, third)
      end
      shedule_proc(prc)
    else
      prc = Proc.new do
        st1_wait_part_3(first, second, third)
      end
      shedule_proc(prc, 30)
    end

  end

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
    @sheduled_tick += 20 if VehicleType::TANK == third

    # Слегка отодвигаем чтобы не помешать двум наземным группам

    shift_x = group_x > third_rec.x ? -2 : 2
    shift_y = group_y > third_rec.y ? -2 : 2
    move_by_type(shift_x, shift_y, third)
    @sheduled_tick += 30
    @sheduled_tick += 10 if VehicleType::TANK == third

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
  end

  def st1_union_2_groups(first, second)

    first_rec = get_reactangle_by_type(first)
    second_rec = get_reactangle_by_type(second)

    p first_rec.inspect
    p second_rec.inspect

    # if (first_rec.x - second_rec.x)

    x = (first_rec.x + second_rec.x) / 2
    y = (first_rec.y + second_rec.y) / 2

    x1 = (x + first_rec.x*2) / 3
    y1 = (y + first_rec.y*2) / 3

    x2 = (x + second_rec.x*2) / 3
    y2 = (y + second_rec.y*2) / 3

    scale_from_x_y_by_type(x1, y1, 1.52, first)
    scale_from_x_y_by_type(x2, y2, 1.52, second)

    next_tick = 140

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

      next_tick = 220

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

      next_tick = 220

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

  end

  def st1_check_union_by_axis(first, second, axis = :x, in_line = false, max_dist = 10)
    p 'st1_check_union_by_axis axis: ' + axis.to_s

    point1 = get_right_reactangle_params_by_type(first)
    point2 = get_right_reactangle_params_by_type(second)

    p point1.inspect
    p point2.inspect

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

  def st1_trhee_in_one(first, second, third)
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

      select_all(77)

      tank_rec = get_reactangle_by_type(VehicleType::TANK)
      air_rec = get_reactangle_by_type(VehicleType::FIGHTER)
      move_selected(tank_rec.x - air_rec.x, tank_rec.y - air_rec.y, 0.7)
    end
    shedule_proc(prc)


    @sheduled_tick += 150

    prc = Proc.new do
      tank_rec = get_reactangle_by_type(VehicleType::TANK)
      scale_from_x_y_by_type(tank_rec.x, tank_rec.y, 0.2)
    end
    shedule_proc(prc)

    @sheduled_tick += 20

    prc = Proc.new do
      tank_rec = get_reactangle_by_type(VehicleType::TANK)
      rotate_from_x_y_by_type(tank_rec.x, tank_rec.y, 2)
    end
    shedule_proc(prc)


    @sheduled_tick += 20

    prc = Proc.new do
      tank_rec = get_reactangle_by_type(VehicleType::TANK)
      scale_from_x_y_by_type(tank_rec.x, tank_rec.y, 0.2)
    end
    shedule_proc(prc)

  end

  private

  def update_all_vechicles
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

  def nuclear_strike
    vechicle = find_first_own_vechicle
    return nil unless vechicle

    p vechicle.inspect

    delayed_move = @move.clone

    delayed_move.action = ActionType::TACTICAL_NUCLEAR_STRIKE
    delayed_move.vehicle_id = vechicle.id
    delayed_move.x = vechicle.x
    delayed_move.y = vechicle.y

    add_move(delayed_move)
  end

  def move_from_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil, length = 1)

      select_all(vehicle_type)

      delayed_move = @move.clone

      rectangle = get_reactangle_by_type(vehicle_type)

      x = rectangle.x unless x
      y = rectangle.y unless y

      delayed_move.action = ActionType::MOVE
      delayed_move.x = (rectangle.x - x) * length
      delayed_move.y = (rectangle.y - y) * length
      delayed_move.max_speed = max_speed if max_speed

      add_move(delayed_move)
  end

  def move_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil)
      select_all(vehicle_type)

      x = 0 unless x
      y = 0 unless y

      move_selected(x, y, max_speed)
  end

  def move_to_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil)
      select_all(vehicle_type)

      rectangle = get_reactangle_by_type(vehicle_type)

      x = rectangle.x unless x
      y = rectangle.y unless y

      move_selected(x - rectangle.x, y - rectangle.y, max_speed)
  end

  def move_selected(x = nil, y = nil, max_speed = nil)
    delayed_move = @move.clone

    delayed_move.action = ActionType::MOVE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.max_speed = max_speed if max_speed

    add_move(delayed_move)
  end

  def get_reactangle_by_type(type = nil, my = true)
    if my
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id == @me.id && (type.nil? || v.type == type) && v.durability > 0}
    else
      selected_vechicles = @all_vechicles.select{|k,v| v.player_id != @me.id && (type.nil? || v.type == type) && v.durability > 0}
    end

    return OpenStruct.new(x: 0, y: 0, min_x: 0, min_y: 0, width_x: 0, width_y: 0, type: type, size: 0) if selected_vechicles.size == 0

    sum_x = 0
    sum_y = 0
    min_x = nil
    min_y = nil

    selected_vechicles.each do |k, v|
      sum_x += v.x
      sum_y += v.y
      min_x = v.x if min_x.nil? || v.x < min_x
      min_y = v.y if min_y.nil? || v.y < min_y
    end

    avrg_x = sum_x / selected_vechicles.size
    avrg_y = sum_y / selected_vechicles.size

    width_x = 2 * (avrg_x - min_x)
    width_y = 2 * (avrg_y - min_y)

    OpenStruct.new(x: avrg_x, y: avrg_y, min_x: min_x, min_y: min_y, width_x: width_x, width_y: width_y, type: type, size: selected_vechicles.size)
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

  def rotate_from_center_by_type(angle = 1, max_speed = nil, type = nil)
    rectangle = get_reactangle_by_type(type)

    rotate_from_x_y_by_type(rectangle.x, rectangle.y, angle, max_speed, type)
  end

  def rotate_from_x_y_by_type(x = 0, y = 0, angle = 1, max_speed = nil, type = nil)
    select_all(type)

    delayed_move = @move.clone

    delayed_move.action = ActionType::ROTATE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.max_angular_speed = max_speed if max_speed
    delayed_move.angle = angle

    add_move(delayed_move)
  end

  def scale_from_center_by_type(factor = 0.1, type = nil)
    rectangle = get_reactangle_by_type(type)

    scale_from_x_y_by_type(rectangle.x, rectangle.y, factor, type)
  end

  def scale_from_x_y_by_type(x = 0, y = 0, factor = 0.1, type = nil)
    select_all(type)

    delayed_move = @move.clone

    delayed_move.action = ActionType::SCALE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.factor = factor

    add_move(delayed_move)
  end

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

  def enemy_position
    res = []
    for i in 0..4
      res << get_reactangle_by_type(i, false)
    end

    res
  end

  def send_all_to_map_center

      select_all

      delayed_move = @move.clone

      delayed_move.action = ActionType::MOVE
      delayed_move.x = @world.width / 2.0
      delayed_move.y = @world.height / 2.0
      delayed_move.max_speed = 0.3

      add_move(delayed_move)
  end

  def select_all(vehicle_type = nil)
    p 'selected all ' + vehicle_type.to_s

    delayed_move = @move.clone
    delayed_move.action = ActionType::CLEAR_AND_SELECT

    if vehicle_type && vehicle_type.to_i > 5
      p 'selected group ' + vehicle_type.to_s
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      delayed_move.group = vehicle_type
    else
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      delayed_move.vehicle_type = vehicle_type if vehicle_type
    end

    add_move(delayed_move)
  end

  def add_to_select(vehicle_type = nil)
    delayed_move = @move.clone

    p 'add to select ' + vehicle_type.to_s

    delayed_move.action = ActionType::ADD_TO_SELECTION

    delayed_move.right = @world.width
    delayed_move.bottom = @world.height
    delayed_move.vehicle_type = vehicle_type if vehicle_type

    add_move(delayed_move)
  end

  def set_group(group)
    delayed_move = @move.clone

    p 'set group ' + group.to_s

    delayed_move.action = ActionType::ASSIGN
    delayed_move.group = group

    add_move(delayed_move)
  end

  def add_move(delayed_move)
    if @sheduled_tick == 0
      @delayed_moves << delayed_move
    else
      tick = @world.tick_index + @sheduled_tick
      @sheduled_moves << OpenStruct.new(tick: tick, move: delayed_move)
    end
  end

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

    print 'D' if DEBUG
    @last_print = 'D'

    delay_move = @delayed_moves.shift
    return nil unless delay_move

    [:action, :left, :top, :right, :bottom, :x, :y, :group, :angle, :factor, :max_speed, :max_angular_speed, :vehicle_type, :facility_id, :vehicle_id].each do |name|
      @move.send(name.to_s + '=', delay_move.send(name))
    end

    if @move == ActionType::CLEAR_AND_SELECT
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

  def vector(angle, distance)
    radians = angle * Math::PI/180
    x = distance * Math.cos(radians)
    y = distance * Math.sin(radians)

    OpenStruct.new(x: x, y: y)
  end

  def add_sheduled_move
    to_delete = []

    @sheduled_moves.each_index do |i|
      sheduled_move = @sheduled_moves[i]
      if @world.tick_index >= sheduled_move.tick
        if sheduled_move.proc
          sheduled_move.proc.call
        elsif sheduled_move.move
          @delayed_moves << sheduled_move.move
        end

        to_delete << i
      end
    end

    while to_delete.any? do
      i = to_delete.pop
      @sheduled_moves.delete_at(i)
    end
  end

  def distance(x1, y1, x2, y2)
    Math.sqrt(sq_distance(x1, y1, x2, y2))
  end

  def sqrt_distance(x1, y1, x2, y2)
    (x1-x2)**2 + (y1-y2)**2
  end

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
