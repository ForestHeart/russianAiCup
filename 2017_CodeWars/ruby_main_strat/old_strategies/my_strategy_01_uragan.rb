require './model/game'
require './model/move'
require './model/player'
require './model/world'
require 'ostruct'

class MyStrategy

  attr_accessor :delayed_moves
  attr_accessor :move
  attr_accessor :world
  attr_accessor :me
  attr_accessor :all_vechicles

  def initialize
    @delayed_moves = []
    @all_vechicles = {}
    puts 'MyStrategy intialized'
  end

  # @param [Player] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    @move = move
    @world = world
    @me = me

    update_all_vechicles

    # if me.remaining_nuclear_strike_cooldown_ticks < 1 && me.next_nuclear_strike_vehicle_id < 1
    #   puts ''
    #   puts 'NUCLEAR INIT'
    #   puts me.inspect
    #   nuclear_strike
    # end

    if world.tick_index == 0
      world.new_vehicles.each do |vechicle|
        @all_vechicles[vechicle.id] = vechicle
      end
    end



    if world.tick_index == 0

      random = Random.new(game.random_seed)

      # puts start_position.inspect

      for i in 0..4
        # puts (get_reactangle_by_type(i).min_x / 70 + 1).to_i
        rotate_from_center_by_type(random.rand - 0.5, i)
      end

    end

    if world.tick_index == 30

      point = near_corner_coor(0)

      scale_from_x_y_by_type(point.x, point.y, 2)
    end

    if world.tick_index == 60
      for i in 0..4
        scale_from_center_by_type(3, i)
      end
    end

    if world.tick_index == 200

      point_100 = near_corner_coor(100)
      point_150 = near_corner_coor(150)
      point_200 = near_corner_coor(200)

      move_to_by_type(point_100.x, point_100.y, VehicleType::ARRV)
      move_to_by_type(point_200.x, point_200.y, VehicleType::FIGHTER)
      move_to_by_type(point_200.x, point_200.y, VehicleType::HELICOPTER)
      move_to_by_type(point_150.x, point_150.y, VehicleType::IFV)
      move_to_by_type(point_200.x, point_200.y, VehicleType::TANK)

    end

    if world.tick_index == 350
      point_150 = near_corner_coor(150)
      for i in 0..4
        scale_from_center_by_type(1, i)
      end
    end

    if world.tick_index == 400
      point_150 = near_corner_coor(150)
      for i in 0..4
        move_to_by_type(point_150.x, point_150.y, i)
      end
    end


    if world.tick_index == 450
      scale_from_center_by_type(0.1)
    end

    if world.tick_index == 500
      point_150 = near_corner_coor(150)
      for i in 0..4
        move_to_by_type(point_150.x, point_150.y, i)
      end
    end

    if world.tick_index == 600
      rotate_from_center_by_type(0.5, 0.2)
    end

    if world.tick_index == 650
      scale_from_center_by_type(0.2)
    end

    if world.tick_index == 700
      point_150 = near_corner_coor(150)
      move_to_by_type(point_150.x, point_150.y)
    end

    if world.tick_index == 750
      send_all_to_map_center
    end

    if world.tick_index > 1000 && (world.tick_index%2000) == 0
      rec = enemy_position.max_by(&:size)
      move_to_by_type(rec.x, rec.y, nil, 0.3)
      puts 'update move'
    end


    if @delayed_moves.any?
      execute_delayed_move
      puts 'delayed moves found'
    end

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

    puts vechicle.inspect

    delayed_move = @move.clone

    delayed_move.action = ActionType::TACTICAL_NUCLEAR_STRIKE
    delayed_move.vehicle_id = vechicle.id
    delayed_move.x = vechicle.x
    delayed_move.y = vechicle.y

    @delayed_moves << delayed_move
  end

  def move_to_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil)

      delayed_move = @move.clone

      delayed_move.action = ActionType::CLEAR_AND_SELECT
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      delayed_move.vehicle_type = vehicle_type if vehicle_type

      @delayed_moves << delayed_move

      delayed_move = @move.clone

      rectangle = get_reactangle_by_type(vehicle_type)

      x = rectangle.x unless x
      y = rectangle.y unless y

      delayed_move.action = ActionType::MOVE
      delayed_move.x = x - rectangle.x
      delayed_move.y = y - rectangle.y
      delayed_move.max_speed = max_speed if max_speed

      @delayed_moves << delayed_move
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

  def rotate_from_center_by_type(angle = 1, max_speed = nil, type = nil)
    rectangle = get_reactangle_by_type(type)

    rotate_from_x_y_by_type(rectangle.x, rectangle.y, angle, max_speed, type)
  end

  def rotate_from_x_y_by_type(x = 0, y = 0, angle = 1, max_speed = nil, type = nil)
    delayed_move = @move.clone

    delayed_move.action = ActionType::CLEAR_AND_SELECT
    delayed_move.right = @world.width
    delayed_move.bottom = @world.height
    delayed_move.vehicle_type = type if type

    @delayed_moves << delayed_move

    delayed_move = @move.clone

    delayed_move.action = ActionType::ROTATE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.max_angular_speed = max_speed if max_speed
    delayed_move.angle = angle

    @delayed_moves << delayed_move
  end

  def scale_from_center_by_type(factor = 0.1, type = nil)
    rectangle = get_reactangle_by_type(type)

    scale_from_x_y_by_type(rectangle.x, rectangle.y, factor, type)
  end

  def scale_from_x_y_by_type(x = 0, y = 0, factor = 0.1, type = nil)
    delayed_move = @move.clone

    delayed_move.action = ActionType::CLEAR_AND_SELECT
    delayed_move.right = @world.width
    delayed_move.bottom = @world.height
    delayed_move.vehicle_type = type if type

    @delayed_moves << delayed_move

    delayed_move = @move.clone

    delayed_move.action = ActionType::SCALE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.factor = factor

    @delayed_moves << delayed_move
  end

  def near_corner_coor(distance = 0)

      vechicle = find_first_own_vechicle
      return nil unless vechicle

      if vechicle.x  < @world.width / 2.0
        x = distance
        y = distance
      else
        x = @world.width - distance
        y = @world.height - distance
      end

      OpenStruct.new(x: x, y: y)
  end

  def start_position
    res = {}
    for i in 0..4
      rec = get_reactangle_by_type(i)
      x = (rec.min_x / 70 + 1).to_i
      y = (rec.min_x / 70 + 1).to_i

      res[i] = OpenStruct.new(x: x, y: y, type: i)
    end

    res
  end

  def enemy_position
    res = []
    for i in 0..4
      res << get_reactangle_by_type(i, false)
    end

    res
  end

  def send_all_to_map_center
      delayed_move = @move.clone

      delayed_move.action = ActionType::CLEAR_AND_SELECT
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      # delayed_move.vehicle_type = 1

      @delayed_moves << delayed_move

      delayed_move = @move.clone

      delayed_move.action = ActionType::MOVE
      delayed_move.x = @world.width / 2.0
      delayed_move.y = @world.height / 2.0
      delayed_move.max_speed = 0.3

      @delayed_moves << delayed_move
  end

  def execute_delayed_move
    return nil if @me.remaining_action_cooldown_ticks > 0

    delay_move = @delayed_moves.shift
    return nil unless delay_move

    [:action, :left, :top, :right, :bottom, :x, :y, :angle, :factor, :max_speed, :max_angular_speed, :vehicle_type, :facility_id, :vehicle_id].each do |name|
      @move.send(name.to_s + '=', delay_move.send(name))
    end
  end
end
