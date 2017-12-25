module MyStrategyControl

  def global_strategy_control
    @my_groups.each do |k, group|
      find_taget(group)
    end
  end

  def find_taget(group)
    if group.vechicle_types[VehicleType::FIGHTER] > 50
      targets = []
      @enemy_groups.each do |k, enemy_group|
        points = 0
        distance_points = 3000 - (enemy_group.position - group.position).r
        atack_points = 0

        size = 0

        enemy_group.vechicle_ids.each do |v_id|
          next if @all_vechicles[v_id].durability < 0.1

          size += 1
          type =  @all_vechicles[v_id].type
          atack_points += @atack_points[VehicleType::FIGHTER][type]
        end

        next if size.zero?

        points = distance_points * (atack_points.to_f / size)

        targets << OpenStruct.new(target_id: enemy_group.id, points: points, action: :atack)
      end

      p targets.inspect

      target = targets.max_by(&:points)

      return nil unless target

      group.set_target(target) if target.points > 0
    end

    if group.vechicle_types[VehicleType::HELICOPTER] > 50
      targets = []
      @enemy_groups.each do |k, enemy_group|
        points = 0
        distance_points = 3000 - (enemy_group.position - group.position).r
        atack_points = 0

        size = 0

        enemy_group.vechicle_ids.each do |v_id|
          next if @all_vechicles[v_id].durability < 0.1

          size += 1
          type =  @all_vechicles[v_id].type
          atack_points += @atack_points[VehicleType::HELICOPTER][type]
        end

        next if size.zero?

        points = distance_points * (atack_points.to_f / size)

        targets << OpenStruct.new(target_id: enemy_group.id, points: points, action: :atack)
      end

      p targets.inspect

      target = targets.max_by(&:points)

      return nil unless target

      group.set_target(target) if target.points > 0
    end
  end
end
