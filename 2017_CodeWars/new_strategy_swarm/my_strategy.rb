require './model/game'
require './model/move'
require './model/player'
require './model/world'
require 'ostruct'
require 'matrix'

require './my_actions'
require './my_helper'
require './modul_p_p'
require './my_classes'
require './my_strategy_control'
require './my_strategy_action'
# require './my_strat_sandwitch'
# require './my_strat_nuclear'
# require './strategy'

require 'pry'

class MyStrategy

  include MyActions
  include MyHelper
  include ModulPP
  include MyStrategyControl
  include MyStrategyAction

  attr_accessor :sheduled_tick
  attr_accessor :delayed_moves
  attr_accessor :sheduled_moves
  attr_accessor :move
  attr_accessor :world
  attr_accessor :me
  attr_accessor :all_vechicles


  GROUND_TYPE = [0, 3, 4]
  AIR_TYPE = [1, 2]
  DEBUG = true

  def initialize
    @pp_size = 16
    @pp_min_group = 3

    # ARRV = 0
    # FIGHTER = 1
    # HELICOPTER = 2
    # IFV = 3
    # TANK = 4

    @atack_points = [
    [0, 0, -1, -1, -5],
    [0, 5, 3, -1, 0],
    [5, -5, 1, -3, 3],
    [0, 1, 5, 1, -3],
    [5, 0, -3, 3, 3]
    ]

    @total_time = 0.to_f
    @last_print = 'p'

    @delayed_moves = []
    @sheduled_tick = 0
    @sheduled_moves = []

    @all_vechicles = {}

    @enemy_groups = {}
    @my_groups = {}

    @selected = -1

    p 'MyStrategy intialized'
  end


  def init(me, world, game, move)
    @move = move
    @world = world
    @me = me

    update_all_vechicles
  end

  # @param [Player] me
  # @param [World] world
  # @param [Game] game
  # @param [Move] move
  def move(me, world, game, move)
    before_move

    init(me, world, game, move)

    if world.tick_index % 50 == 0
      calculate_pp
      update_group_position


      if DEBUG && world.tick_index % 100 == 0
        p ''
        p 'Enemies groups:'
        @enemy_groups.each do |k, group|
          awesome_print group
        end

        p ''
        p 'My groups:'
        @my_groups.each do |k, group|
          awesome_print group
        end
      end
    end

    if world.tick_index % 5 == 0
      update_group_position
    end

    if world.tick_index == 0
      select_vechicles(VehicleType::FIGHTER)
      assign_group
    end

    if world.tick_index == 250
      select_vechicles(VehicleType::HELICOPTER)
      assign_group
    end

    if world.tick_index > 5 && world.tick_index % 50 == 7
      # look at all map, choose action for all MyGroup
      global_strategy_control
    end

    if world.tick_index > 10 && world.tick_index % 5 == 0
      # Look at all my groups, do action
      my_group_action
    end

    # run_strategies if @strategies.any?
    after_move

  rescue => e
    puts '================================================================================='
    puts "An error of type #{e.class} happened, message is #{e.message}"
    puts '================================================================================='

    if DEBUG
      raise e
    end
  end

  def before_move
    @start_time = Time.now if DEBUG

    @sheduled_tick = 0
  end

  def after_move

    if @sheduled_moves.any?
      check_sheduled_move
    end

    if @delayed_moves.any?
      execute_delayed_move
    end

    if DEBUG
      @total_time += Time.now - @start_time
      show_time
    end
  end

  def show_time
    if world.tick_index % 200 == 0
      p 'Total time on ' + world.tick_index.to_s + ' is ' + @total_time.to_s
    end
  end

end
