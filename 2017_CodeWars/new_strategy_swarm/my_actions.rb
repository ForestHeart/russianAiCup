module MyActions

  # ================================================================================
  #                           SELECT and ASSIGN
  # ================================================================================

  def scale_to(group, vector, factor = 1, max_speed = nil)


    select_vechicles(group.id)

    proc = Proc.new do
      @move.action = ActionType::SCALE

      @move.group = group.id

      @move.x = vector[0]
      @move.y = vector[1]

      @move.factor = factor
      @move.max_speed = max_speed if max_speed

      p 'Scale group:' + group.id.to_s + ' to vector:' + vector.inspect
    end

    delayed_move = DelayedMove.new(proc, nil, nil, group.id)
    add_move(delayed_move)
  end


  def nuke_to(position, vechicle)

    proc = Proc.new do
      @move.action = ActionType::TACTICAL_NUCLEAR_STRIKE

      @move.x = position[0]
      @move.y = position[1]

      @move.vehicle_id = vechicle.id

      p 'Nuke to:' + position.inspect
    end

    delayed_move = DelayedMove.new(proc)
    add_move(delayed_move)
  end

  def  rotate_to(group, vector, angle = 90, max_speed = nil)
    select_vechicles(group.id)

    proc = Proc.new do
      @move.action = ActionType::ROTATE

      @move.group = group.id

      radians = angle * Math::PI/180
      @move.angle = radians

      @move.x = vector[0]
      @move.y = vector[1]

      @move.max_speed = max_speed if max_speed

      p 'Rotate group:' + group.id.to_s + ' to vector:' + vector.inspect
    end

    delayed_move = DelayedMove.new(proc, nil, nil, group.id)
    add_move(delayed_move)
  end

  def move_to(group, vector)

    if group.move_to.r > 20 && vector.r > 20

      if (!group.move_to.independent?(vector) || (group.move_to.angle_with(vector) * 180 / Math::PI).to_i <= 10) && vector.r > 20
        p 'move group:' + group.id.to_s + ' to skipped, the same way'
        return nil
      end
    end


    select_vechicles(group.id)

    group.move_to = vector

    proc = Proc.new do
      @move.action = ActionType::MOVE

      @move.group = group.id

      @move.x = vector[0]
      @move.y = vector[1]


      p 'move group:' + group.id.to_s + ' to vector:' + vector.inspect
    end

    delayed_move = DelayedMove.new(proc, nil, nil, group.id)
    add_move(delayed_move)
  end

  def select_vechicles(group_id = nil, area = nil)

    area = Area.new(Vector[0, 0], Vector[@world.width, @world.height]) unless area
    proc = Proc.new do
      @move.action = ActionType::CLEAR_AND_SELECT

      if group_id.to_i > 5
        text = 'select group:' + group_id.to_s
        @move.group = group_id
      else
        text = 'select vehicle_type:' + group_id.to_s
        @move.vehicle_type = group_id if group_id
      end

      @move.left = area.start_vector[0]
      @move.top = area.start_vector[1]
      @move.right = area.end_vector[0]
      @move.bottom = area.end_vector[1]

      p text
    end

    delayed_move = DelayedMove.new(proc, nil, ActionType::CLEAR_AND_SELECT, group_id)
    add_move(delayed_move)
  end

  def assign_group(type = nil)
    proc = Proc.new do
      id = @my_groups.keys.max
      id = id.nil? ? 10: id + 1

      group = MyGroup.new(id, type)

      @move.action = ActionType::ASSIGN
      @move.group = group.id

      @all_vechicles.each do |vechicle_id, v|
        if v.player_id == @me.id && v.selected
          group.size += 1
          group.vechicle_ids << v.id

          group.vechicle_types[v.type] += 1
        end

      end

      @my_groups[group.id] = group
    end

    delayed_move = DelayedMove.new(proc)
    add_move(delayed_move)
  end

end
