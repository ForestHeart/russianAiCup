
class Vehicle < CircularUnit
  attr_accessor :speed
  # attr_reader :speed_array

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

    @speed = 0
    # @speed_array = [0]
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

    @speed = (vehicle_update.x - @x).abs + (vehicle_update.y - @y).abs

    # @speed_array << @speed
    # @speed_array.shift if @speed_array.size > 5

    # if @last_5_speed.size == 5 && @speed.r > 0
    #   binding.pry
    #   raise 'stop'
    # end

    @x = vehicle_update.x
    @y = vehicle_update.y
  end
end
