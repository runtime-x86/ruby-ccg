# encoding: utf-8
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
# Version: 0.2

module Ccg
	# Linear state machine. Or something.
	# It goes 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 0.
	class State
		attr_reader :current_state, :initial_player
		def initialize
			@states_work = {}
			@states = [
				:state_p1_start, :state_p1_act, :state_p1_end,
				:state_p2_start, :state_p2_act, :state_p2_end
			]
			@current_state = :state_p1_start
			@current_state_index = @states.find_index(@current_state)
			@started = false
			self
		end
		# Actions to do after given state occurs.
		def on(state, &closure)
			if @states.include?(state)
				@states_work[state] = closure
			end
			self
		end
		# Activate initial action. Call after setting all on()'s.
		def run!
			@started = true
			action = @states_work[@current_state]
			unless action.nil?
				action.call
			end
			self
		end
		# Move to next state.
		def next!
			@current_state_index += 1
			if @current_state_index > 5
				@current_state_index = 0
			end
			@current_state = @states[@current_state_index]
			action = @states_work[@current_state]
			unless action.nil?
				action.call
			end
			self
		end
		def end_turn!
			end_index = (@current_state_index < 3) ? 2 : 5
			@current_state_index.upto(end_index) do |index|
				self.next!
			end
			self
		end
		# Resets state. on()'s are not reset thought.
		def reset!
			@current_state = :state_p1_start
			@started = false
			self
		end
		# Only use before calling run!
		def initial_player=(player = :player_1)
			if @started
				raise 'You cannot modify Ccg::State::initial_player after run method was called.'
			else
				@current_state = (player == :player_1) ? :state_p1_start : :state_p2_start
				@current_state_index = @states.find_index(@current_state)
			end
			player
		end
	end
end
