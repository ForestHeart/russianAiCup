module MyActions

  # ================================================================================
  #                           MOVES
  # ================================================================================


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

    add_move(delayed_move, vehicle_type)
  end

  def move_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil)
    select_all(vehicle_type)

    x = 0 unless x
    y = 0 unless y

    move_selected(x, y, max_speed, vehicle_type)
  end

  def move_to_by_type(x = nil, y = nil, vehicle_type = nil, max_speed = nil)
    select_all(vehicle_type)

    rectangle = get_reactangle_by_type(vehicle_type)

    x = rectangle.x unless x
    y = rectangle.y unless y

    move_selected(x - rectangle.x, y - rectangle.y, max_speed, vehicle_type)
  end

  def move_selected(x = nil, y = nil, max_speed = nil, vehicle_type = -1)
    delayed_move = @move.clone

    delayed_move.action = ActionType::MOVE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.max_speed = max_speed if max_speed

    add_move(delayed_move, vehicle_type)
  end

  # ================================================================================
  #                           ROTATE
  # ================================================================================

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
    delayed_move.max_speed = max_speed if max_speed
    delayed_move.angle = angle

    add_move(delayed_move, type)
  end

  # ================================================================================
  #                           SCALE
  # ================================================================================

  def scale_from_center_by_type(factor = 0.1, type = nil, max_speed = nil)
    rectangle = get_reactangle_by_type(type)

    scale_from_x_y_by_type(rectangle.x, rectangle.y, factor, type, max_speed)
  end

  def scale_from_x_y_by_type(x = 0, y = 0, factor = 0.1, type = nil, max_speed = nil)
    select_all(type)

    delayed_move = @move.clone

    delayed_move.action = ActionType::SCALE
    delayed_move.x = x
    delayed_move.y = y
    delayed_move.factor = factor
    delayed_move.max_speed = max_speed if max_speed

    add_move(delayed_move, type)
  end

  def send_all_to_map_center

      select_all

      delayed_move = @move.clone

      delayed_move.action = ActionType::MOVE
      delayed_move.x = @world.width / 2.0
      delayed_move.y = @world.height / 2.0
      delayed_move.max_speed = 0.3

      add_move(delayed_move, vehicle_type)
  end

  # ================================================================================
  #                           SELECTION
  # ================================================================================

  def select_facility(facility)
    p 'selected facility ' + facility.id.to_s

    delayed_move = @move.clone
    delayed_move.action = ActionType::CLEAR_AND_SELECT

    delayed_move.top = facility.top
    delayed_move.bottom = facility.top + 64

    delayed_move.left = facility.left
    delayed_move.right = facility.left + 64

    add_move(delayed_move)
  end


  def select_area(x1, y1, x2, y2)
    p 'selected area '

    delayed_move = @move.clone
    delayed_move.action = ActionType::CLEAR_AND_SELECT

    delayed_move.top = y1
    delayed_move.bottom = y2

    delayed_move.left = x1
    delayed_move.right = x2

    add_move(delayed_move, nil)
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

    add_move(delayed_move, vehicle_type)
  end

  def deselect_all(vehicle_type = nil)
    p 'deselected all ' + vehicle_type.to_s

    delayed_move = @move.clone
    delayed_move.action = ActionType::DESELECT

    if vehicle_type && vehicle_type.to_i > 5
      p 'deselected group ' + vehicle_type.to_s
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      delayed_move.group = vehicle_type
    else
      delayed_move.right = @world.width
      delayed_move.bottom = @world.height
      delayed_move.vehicle_type = vehicle_type if vehicle_type
    end

    add_move(delayed_move, vehicle_type)
  end

  def add_to_select(vehicle_type = nil)
    delayed_move = @move.clone

    p 'add to select ' + vehicle_type.to_s

    delayed_move.action = ActionType::ADD_TO_SELECTION

    delayed_move.right = @world.width
    delayed_move.bottom = @world.height
    delayed_move.vehicle_type = vehicle_type if vehicle_type

    add_move(delayed_move, vehicle_type)
  end

  def dismiss_selected(group)
    delayed_move = @move.clone

    p 'dissmis selected ' + group.to_s

    delayed_move.action = ActionType::DISMISS
    delayed_move.group = group
    add_move(delayed_move, group)
  end

  def set_group(group)
    delayed_move = @move.clone

    p 'set group ' + group.to_s

    delayed_move.action = ActionType::ASSIGN
    delayed_move.group = group

    add_move(delayed_move, group)
  end

  def set_facility_production(facility, type = nil)
    delayed_move = @move.clone

    p 'set facility ' + facility.id.to_s + ' to type: ' + type.to_s

    delayed_move.action = ActionType::SETUP_VEHICLE_PRODUCTION
    delayed_move.facility_id = facility.id
    delayed_move.vehicle_type = type

    add_move(delayed_move)
  end


  # ================================================================================
  #                           NUCLEAR
  # ================================================================================


  def nuclear_strike(x, y, vechicle)

    p ' =========== NUCLEAR ================'
    p 'x: ' + x.to_i.to_s + 'y: ' + y.to_i.to_s
    p vechicle.inspect

    delayed_move = @move.clone

    delayed_move.action = ActionType::TACTICAL_NUCLEAR_STRIKE
    delayed_move.vehicle_id = vechicle.id
    delayed_move.x = x
    delayed_move.y = y

    add_move(delayed_move)
  end

end
