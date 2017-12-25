class Strategy
  attr_accessor :f_name
  attr_accessor :group
  attr_accessor :min_tick
  attr_accessor :mod_tick
  attr_accessor :shift_tick
  attr_accessor :max_speed

  # захватывать задния (воздух не захватывает)
  attr_accessor :capture_facility

  # первый тип атакуемых и дистанция атаки
  attr_accessor :atack_unity_types
  attr_accessor :target_distance

  # второй тип атакуемых, если первых не осталось
  attr_accessor :second_atack_unity_types
  attr_accessor :second_target_distance

  # для запоминания кода поворачиваться и собираться в кучку
  attr_accessor :rotated_angle
  attr_accessor :rotated_since
  attr_accessor :scaled_since
  attr_accessor :no_scaling_and_rotating

  # коэфициенты для определения цели
  attr_accessor :facility_distance_k
  attr_accessor :compacting_k

  # для сортировки групп, чтобы ходили по очереди
  attr_accessor :last_move

  # избегаем опасных ситуаций при атаке противника
  attr_accessor :avoid_agressive
  attr_accessor :agressive_groups
  attr_accessor :agressive_count

  # атакуем с поворотами, для самолетов
  attr_accessor :atack_rotating
  # проверяем группу при запуске что уже етсь ход (для исключения ядерки)
  attr_accessor :check_group

  # убирает поиск отдаленного юнита
  attr_accessor :nuker

  # выживаем группой
  attr_accessor :keep_alive
  # мин размер с котрого выживаем
  attr_accessor :keep_alive_size
  # мин жизней с которых выживаем
  attr_accessor :keep_alive_durability
  # мин расстояние с которого выживаем
  attr_accessor :keep_alive_distance
  # флаг что выживаем
  attr_accessor :keeping_alive
  # гоу лечиться
  attr_accessor :healing
  attr_accessor :healing_percent
  attr_accessor :need_healing_size
  attr_accessor :need_durability
  attr_accessor :start_healing

  attr_accessor :mod_tick_slow
  attr_accessor :mod_tick_mid
  attr_accessor :mod_tick_fast


  attr_accessor :fog_x
  attr_accessor :fog_y

  attr_accessor :move_to_x
  attr_accessor :move_to_y


  def initialize(f_name, group, min_tick, mod_tick, shift_tick = 0, max_speed = nil)
    @f_name = f_name
    @group = group
    @min_tick = min_tick
    @mod_tick = mod_tick
    @shift_tick = shift_tick
    @max_speed = max_speed

    @capture_facility = true

    @atack_unity_types = nil
    @target_distance = 10

    @second_atack_unity_types = nil
    @second_target_distance = 30

    @no_scaling_and_rotating = false

    @rotated_angle = 1
    @rotated_since = 0
    @scaled_since = -10

    @facility_distance_k = 2

    @last_move = 0
    @avoid_agressive = false
    @agressive_groups = [0, 1, 2, 3, 4]
    @agressive_count = 10

    @compacting_k = 10

    @atack_rotating = false

    @check_group = true

    @nuker = false
    @keep_alive = false
    @keep_alive_size = 7
    @keep_alive_durability = 500
    @keep_alive_distance = 44
    @keeping_alive = false

    @fog_x = 500
    @fog_y = 500


    @start_healing = false
    @healing = false
    @healing_percent = 70
    @need_healing_size = 10
    @need_durability = 1000


    @mod_tick_slow = 120
    @mod_tick_mid = 60
    @mod_tick_fast = 30

    @move_to_x = -50
    @move_to_y = -50

    # p self.inspect
  end

  def run?(tick)
    tick.to_i > min_tick && (tick.to_i % mod_tick == shift_tick)
  end
end
