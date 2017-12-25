class Group
  attr_accessor :id
  attr_accessor :size
  attr_accessor :vechicle_types
  attr_accessor :vechicle_ids
  attr_accessor :position
  attr_accessor :speed
  attr_accessor :avrg_speed

  def initialize(id)
    @id = id
    @size = 0
    @vechicle_types = {0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0}
    @vechicle_ids = []
    @position = Vector[0,0]
    @speed = Vector[0,0]
    @avrg_speed = Vector[0,0]
  end

  def update_params(params)
    self.position = params.position
    self.speed = params.speed
    self.avrg_speed = params.avrg_speed
  end

  def find_nearest_vehicle(all_vechicles, position, min_dist = nil, max_dist = nil)
    choosen_dist = nil
    nearest_vechicle = nil

    self.vechicle_ids.each do |v_id|
      next if all_vechicles[v_id].durability < 0.1

      dist = (all_vechicles[v_id].position - position).r

      next if !min_dist.nil? && dist < min_dist
      next if !max_dist.nil? && dist > max_dist

      if choosen_dist.nil? || choosen_dist >= dist
        choosen_dist = dist
        nearest_vechicle = all_vechicles[v_id]
      end
    end

    nearest_vechicle
  end

end

class MyGroup < Group

  attr_accessor :target_id
  attr_accessor :move_to
  attr_accessor :type
  attr_accessor :action
  attr_accessor :wait_tick
  # scaled and rotated to center at tick
  attr_accessor :scaled_at
  attr_accessor :rotated_at

  def initialize(id, type = nil)
    super(id)
    @action = :wait
    @target_id = nil
    @move_to = Vector[0,0]
    @type = type
    @wait_tick = 0
    @scaled_at = 0
    @rotated_at = 0
  end

  def set_target(target)
    self.action = target.action
    self.target_id = target.target_id
  end
end


class DelayedMove
  attr_accessor :proc
  attr_accessor :tick
  attr_accessor :select_group
  attr_accessor :action_type

  def initialize(proc = nil, tick = 0, action_type = nil, select_group = -1)
    tick = 0 unless tick

    @proc = proc
    @tick = tick
    @select_group = select_group
    @action_type = action_type
  end
end


class Area
  attr_accessor :start_vector
  attr_accessor :end_vector

  def initialize(start_vector = nil, end_vector = nil)
    @start_vector = start_vector ? start_vector : Vector[0,0]
    @end_vector = end_vector ? end_vector : Vector[500, 500]
  end
end



class Vehicle < CircularUnit
  attr_reader :position
  attr_reader :speed
  attr_reader :speed_array

  def initialize(id, x, y, radius, player_id, durability, max_durability, max_speed, vision_range, squared_vision_range,
                 ground_attack_range, squared_ground_attack_range, aerial_attack_range, squared_aerial_attack_range,
                 ground_damage, aerial_damage, ground_defence, aerial_defence, attack_cooldown_ticks,
                 remaining_attack_cooldown_ticks, type, aerial, selected, groups)
    super(id, x, y, radius)

    @player_id = player_id
    @durability = durability
    @max_durability = max_durability
    @max_speed = max_speed
    @vision_range = vision_range
    @squared_vision_range = squared_vision_range
    @ground_attack_range = ground_attack_range
    @squared_ground_attack_range = squared_ground_attack_range
    @aerial_attack_range = aerial_attack_range
    @squared_aerial_attack_range = squared_aerial_attack_range
    @ground_damage = ground_damage
    @aerial_damage = aerial_damage
    @ground_defence = ground_defence
    @aerial_defence = aerial_defence
    @attack_cooldown_ticks = attack_cooldown_ticks
    @remaining_attack_cooldown_ticks = remaining_attack_cooldown_ticks
    @type = type
    @aerial = aerial
    @selected = selected
    @groups = groups

    @position = Vector[x,y]
    @speed = Vector[0,0]
    @speed_array = [Vector[0,0]]
  end


  # @param [VehicleUpdate] vehicle_update
  def update(vehicle_update)
    if @id != vehicle_update.id
      raise ArgumentError, "Received wrong message [actual=#{vehicle_update.id}, expected=#{@id}]."
    end

    @durability = vehicle_update.durability
    @remaining_attack_cooldown_ticks = vehicle_update.remaining_attack_cooldown_ticks
    @selected = vehicle_update.selected
    @groups = vehicle_update.groups

    @speed = Vector[vehicle_update.x, vehicle_update.y] - Vector[@x, @y]
    @position = Vector[@x,@y]

    @speed_array << @speed
    @speed_array.shift if @speed_array.size > 5

    # if @last_5_speed.size == 5 && @speed.r > 0
    #   binding.pry
    #   raise 'stop'
    # end

    @x = vehicle_update.x
    @y = vehicle_update.y
  end
end

class Vector

  def rotate(degrees)
    radians = degrees.to_f * Math::PI/180
    x2 = self[0]
    y2 = self[1]

    cos = Math.cos(radians); sin = Math.sin(radians)

    self.class[
      (x2*cos - y2*sin).round(10),
      (x2*sin + y2*cos).round(10)
    ]
  end

  def change_r(dist)
    n = self.r

    self * (n + dist) / n
  end

end
