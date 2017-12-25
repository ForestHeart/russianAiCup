module ModulPP

  DEBUG = true

  def calculate_pp

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
      next if vechicle.durability < 0.1

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

    if DEBUG
      # p 'PP:'
      # awesome_print @active_pp
    end

    group_pp

  end

  private

  def group_pp
    @old_enemy_groups = @enemy_groups.dup
    @enemy_groups = {}

    @active_pp.each do |pole|
      if pole.enemies.positive?
        if pole.group.nil?
          next if pole.enemies <= @pp_min_group
          id = @enemy_groups.keys.max
          id = id.nil? ? @old_enemy_groups.keys.max.to_i + 1: id + 1

          group = Group.new(id)

          @enemy_groups[id] = group

          join_pole_to_group(group, pole)
        else
          group = @enemy_groups[pole.group]
        end

        assign_neibor_group(group, pole)
      end
    end

    rename = []

    @enemy_groups.each do |id, group|
      @old_enemy_groups.each do |id, old_group|
        common_size = (group.vechicle_ids & old_group.vechicle_ids).size.to_f

        if common_size / group.vechicle_ids.size > 0.6 && common_size / old_group.vechicle_ids.size > 0.6
          rename << OpenStruct.new(from: group.id, to: old_group.id)
          next
        end
      end
    end

    rename.each do |ids|
      @enemy_groups[ids.to] = @enemy_groups.delete(ids.from)
      @enemy_groups[ids.to].id = ids.to
    end

  end

  def assign_neibor_group(group, pole)

    if pole.n < @world.width / @pp_size
      neibr_pole = @pp[pole.n + 1][pole.m]
      join_pole_to_group(group, neibr_pole) if !neibr_pole.nil? && neibr_pole.group.nil?
      join_groups(group, neibr_pole.group) if !neibr_pole.nil? && !neibr_pole.group.nil? && group.id != neibr_pole.group
    end

    if pole.m < @world.height / @pp_size
      neibr_pole = @pp[pole.n][pole.m + 1]
      join_pole_to_group(group, neibr_pole) if !neibr_pole.nil? && neibr_pole.group.nil?
      join_groups(group, neibr_pole.group) if !neibr_pole.nil? && !neibr_pole.group.nil? && group.id != neibr_pole.group
    end

    if pole.n > 0
      neibr_pole = @pp[pole.n - 1][pole.m]
      join_pole_to_group(group, neibr_pole) if !neibr_pole.nil? && neibr_pole.group.nil?
      join_groups(group, neibr_pole.group) if !neibr_pole.nil? && !neibr_pole.group.nil? && group.id != neibr_pole.group
    end

    if pole.m > 0
      neibr_pole = @pp[pole.n][pole.m - 1]
      join_pole_to_group(group, neibr_pole) if !neibr_pole.nil? && neibr_pole.group.nil?
      join_groups(group, neibr_pole.group) if !neibr_pole.nil? && !neibr_pole.group.nil? && group.id != neibr_pole.group
    end
  end

  def join_pole_to_group(group, pole)
    return nil if pole.enemies <= @pp_min_group

    pole.group = group.id
    group.size += pole.enemies
    group.vechicle_ids = group.vechicle_ids | pole.enemy_ids

    group.vechicle_types.each do |id, value|
      group.vechicle_types[id] += pole.enemy_types[id]
    end
  end

  def join_groups(group, group_id)
    old_group = @enemy_groups[group_id]

    group.size += old_group.size
    group.vechicle_ids = group.vechicle_ids | old_group.vechicle_ids

    group.vechicle_types.each do |id, value|
      group.vechicle_types[id] += old_group.vechicle_types[id]
    end

    @enemy_groups.delete(group_id)

    @active_pp.each do |pole|
      pole.group = group.id if pole.group == group_id
    end

  end

end
