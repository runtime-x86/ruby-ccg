# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2

module Ccg
	# Main game class.
	# You must create it to use anything here like, say,
	# card_game = Ccg::Game.new
	class Game
		# An array of #Ccg::Hero objects with a size of 2.
		attr_reader :heroes
		# Current game state. See #Ccg::State for details.
		attr_reader :state
		# Want to play card 'w2p_card'
		attr_accessor :w2p_card
		# ... at position 'w2p_card_at_pos' for current hero.
		attr_accessor :w2p_card_at_pos

		def initialize
			@closures = {}
			@state = Ccg::State.new
			@state.on(:state_p1_start) do
				@w2p_card = nil; @w2p_card_at_pos = nil
				@heroes[0].start_turn!
			end
			@state.on(:state_p1_act) do
				unless @w2p_card.nil? || @w2p_card_at_pos.nil?
					play_card!(0, @w2p_card, @w2p_card_at_pos)
				end
			end
			@state.on(:state_p1_end) do
				end_turn!(0)
			end
			@state.on(:state_p2_start) do
				@w2p_card = nil; @w2p_card_at_pos = nil
				@heroes[1].start_turn!
			end
			@state.on(:state_p2_act) do
				unless @w2p_card.nil? || @w2p_card_at_pos.nil?
					play_card!(1, @w2p_card, @w2p_card_at_pos)
				end
			end
			@state.on(:state_p2_end) do
				end_turn!(1)
			end
			self.start_new!
			self
		end

		# Starts a new game. Resets state and heroes' info.
		def start_new!
			@last_played_slot = nil
			@game_first_step = true
			@heroes = [Ccg::Hero.new, Ccg::Hero.new]
			@state.reset!
			self
		end

		# Handlers for various events.
		#
		# *Usage*:
		#
		#     ccg_obj.on(action) do |params|
		#         # Some code here.
		#     end
		#
		# *Events* (event, params - description):
		#
		# [:creature_attacks] hero, slot_number - occurs after any creature attack
		def on(action, &closure)
			if [:creature_attacks].include?(action)
				@closures[action] = closure
			end
			self
		end

		# Find card (a Hash) by name. Returns nil if nothing found.
		def find_card(name)
			Ccg::cards.each_value do |card_list|
				found = card_list.index{ |x| x['name'] == name }

				# Return first found result. Names should be unique anyway.
				unless found.nil?
					return card_list[found]
				end
			end
			nil # Nothing found
		end

		private

		def play_card!(hero_num, card, position)
			# Check 'on-play' abilities.
			current_hero = @heroes[hero_num] # Attacking hero
			other_hero = @heroes[(hero_num - 1).abs] # Defending hero

			# If card['abilities'] is nil make variable an empty array.
			card_abilities = card['abilities'] || []
			# Check abilities.
			card_abilities.each do |ability|
				case ability['name']
					when 'Blast'
						if other_hero.field.position[position].empty?
							other_hero.do_damage!(ability['param'].to_i, :magic)
						else
							other_hero.field.position[position].do_damage!(ability['param'].to_i, :magic)
						end

					# Increase 'param' mana by 1.
					when 'Boost'
						current_hero.mana_change!(1, ability['param'])

					# Increase 'param' mana by 2.
					when 'Charge'
						current_hero.mana_change!(2, ability['param'])

					# Each enemy creature take a number of damage equal to it's cost * @param
					when 'Disrupter'
						other_hero.do_damage_creatures!(slot.cost * ability['param'].to_i, :magic)

					# Increase 'param' mana by 3.
					when 'Drive'
						current_hero.mana_change!(3, ability['param'])

					# Decrease foe 'param' mana by 1.
					when 'Shock'
						other_hero.mana_change!(-1, ability['param'])

					# Decrease foe 'param' mana by 2.
					when 'Awe'
						other_hero.mana_change!(-2, ability['param'])

					# Decrease Law mana by 'param' for both players.
					when 'Law breaker'
						current_hero.mana_change!(-1 * ability['param'].to_i, 'Law')
						other_hero.mana_change!(-1 * ability['param'].to_i, 'Law')

					# decreases all foe's mana (except Psychic and Chaos)
					# by 'param', increases foe's Chaos mana by 'param'.
					when 'Chaotic visage'
						other_hero.mana_change_all!(-1 * ability['param'].to_i, ['Chaos', 'Psychic'])
						other_hero.mana_change!(ability['param'].to_i, 'Chaos')

					# Each enemy creature take a number of damage equal to it's attack * @param
					when 'Justice'
						other_hero.do_damage_creatures!(slot.attack * ability['param'].to_i, :magic)

					# Damage to enemy hero and opposite creature equals to opposite creature's attack
					when 'Hypnosis'
						unless other_hero.field.position[position].empty?
							other_hero.do_damage!(other_hero.field.position[position].attack)
							other_hero.field.position[position].do_damage!(other_hero.field.position[position].attack)
						end

					# Damage to enemy hero equals to your @param mana + 3.
					when 'Raw power'
						other_hero.do_damage!(current_hero.mana[ability['param']] + 3, :magic)

					when 'damage'
						# self method
						each_target(current_hero, other_hero, ability['target'], position) do |t|
							t.do_damage!(ability['param'].to_i, :magic)
						end

					when 'heal'
						each_target(current_hero, other_hero, ability['target'], position) do |t|
							t.do_heal!(ability['param'].to_i)
						end

					when 'destroy'
						each_target(current_hero, other_hero, ability['target'], position) do |t|
							t.do_destroy!
						end

					when 'L-D mana swap'
						current_hero.mana_swap!('Light', 'Darkness')
				end # case
			end # each

			# Assign card to a slot.
			if ['creature', 'wall'].include?(card['type'])
				current_hero.field.position[position].assign!(card)
				@last_played_slot = position # Mark played slot.
			end

			# Check bonuses
			@heroes.each do |hero|
				hero.check_bonus!
			end

			# Reduce mana
			current_hero.mana_change!(-1 * card['cost'].to_i, card['base_mana_type'])

			# Additional cost for class cards
			current_hero.mana_change!(-2, card['add']) unless card['add'].nil?

			self
		end

		# All creatures attack.
		def end_turn!(hero_num)
			current_hero = @heroes[hero_num] # Attacking hero
			other_hero = @heroes[(hero_num - 1).abs] # Defending hero
			(0..5).reject{ |num| num == @last_played_slot }.each do |x|
				all_alive = !(current_hero.destroyed? || other_hero.destroyed?) 
				if all_alive && !current_hero.field.position[x].empty?
					creature_attack!(current_hero, other_hero, x) # self method
					unless @closures[:creature_attacks].nil?
						@closures[:creature_attacks].call(@heroes[hero_num], x)
					end
				end
			end

			if @game_first_step
				# Mana boost for the 2nd player on the 1st turn.
				other_hero.mana.each_key do |key|
					other_hero.mana_change!(1, key)
				end
				@game_first_step = false
			end

			@last_played_slot = nil
			self
		end

		# current_hero's creature in slot 'creature_position' atacks
		# other_hero's creature (or other_hero itself)
		def creature_attack!(current_hero, other_hero, creature_position)
			current_creature = current_hero.field.position[creature_position]
			other_creature = other_hero.field.position[creature_position]

			return self if current_creature.empty? # Sanity check

			frost_used = false # 'Frost' ability flag
			annihilator_used = false # Special flag
			attack_type = :normal # Type of attack
			fierce_creature = false # Creature with a 'Fierce' ability
			martyr_damage = nil # Damage for 'Martyr' ability

			# Creature attacks
			attempt_damage = current_creature.attack
			attempt_damage = 0 if attempt_damage < 0

			current_creature.abilities.each do |ability|
				case ability['name']
					# Auto-destroys with attack any creature of 'wall' type.
					when 'Annihilator'
						unless other_creature.nil?
							other_creature.do_destroy! if other_creature.card_type == 'wall'
							annihilator_used = true
						end

					# Damages enemy creatures and hero by 1 every turn.
					# Does NOT stack with itself.
					when 'Frost'
						other_hero.do_damage_all!(1) unless frost_used

					# Heals friendly creatures by @param every turn
					# (but NOT itself).
					when 'Healing aura'
						current_hero.do_heal_all!(ability['param'].to_i, [creature_position])

					# Heals owner by @param every turn.
					when 'Healing link'
						current_hero.do_heal!(ability['param'].to_i)

					# Adds +1 @param mana every turn.
					when 'Link'
						current_hero.mana_change!(1, ability['param'])

					# Heals @param damage to itself every turn.
					when 'Regeneration'
						current_creature.do_heal!(ability['param'].to_i)

					# Deals @param damage to enemy hero every turn.
					when 'Slayer'
						other_hero.do_damage!(ability['param'].to_i)

					# Attacks all enemies, including enemy hero.
					when 'Tactician'
						attack_type = :tactician

					# Attacks all enemy creatures.
					when 'Wave attack'
						attack_type = :wave

					# Martyr. Takes @param damage every turn.
					when 'Martyr'
						martyr_damage = ability['param'].to_i
				end
			end

			# Check opposite creature's abilities
			unless other_creature.empty?
				other_creature.abilities.each do |ability|
					case ability['name']
						when 'Fierce'
							fierce_creature = true
					end
				end
			end

			if attack_type == :tactician
				other_hero.do_damage_all!(attempt_damage)
			else
				# Creature attack unless 'annihilator_used' flag set.
				unless annihilator_used
					if other_creature.empty?
						other_hero.do_damage!(attempt_damage)
					else
						other_creature.do_damage!(attempt_damage)
						# Fierce creature strikes back!
						if fierce_creature
							current_creature.do_damage!(attempt_damage / 2)
							unless @closures[:creature_attacks].nil?
								@closures[:creature_attacks].call(
									other_hero, creature_position
								)
							end
						end
					end
				end

				if attack_type == :wave
					# Do not damage current opposite slot twice
					other_hero.do_damage_creatures!(
						attempt_damage, :normal, [creature_position]
					)
				end
			end

			# Apply 'Martyr' damage
			unless (martyr_damage.nil? || current_creature.empty?)
				current_creature.do_damage!(martyr_damage)
			end

			# Check bonuses for both heroes
			@heroes.each do |hero|
				hero.check_bonus!
			end

			self
		end

		# Run code for each @target.
		def each_target(current_hero, other_hero, target, position)
			current_field = current_hero.field
			other_field = other_hero.field
			case target
				# your hero and creatures
				when 'self:all'
					current_field.position.each { |slot| yield slot unless slot.empty? }
					yield current_hero

				# your creatures
				when 'self:creatures'
					current_field.position.each { |slot| yield slot unless slot.empty? }

				# one of your creatures
				when 'self:one'
					yield current_field.position[position] unless current_field.position[position].empty?

				# your hero
				when 'self:hero'
					yield current_hero

				# enemy hero and creatures
				when 'foe:all'
					other_field.position.each { |slot| yield slot unless slot.empty? }
					yield other_hero

				# enemy creatures
				when 'foe:creatures'
					other_field.position.each { |slot| yield slot unless slot.empty? }

				# one of enemy creatures
				when 'foe:one'
					yield other_field.position[position] unless other_field.position[position].empty?

				# enemy hero
				when 'foe:hero'
					yield other_hero
			end
		end

	end # class
end
