# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2-1

module Ccg
	class Hero
		attr_accessor :hp, :max_hp, :name
		attr_reader :character_class
		# Is a hash: mana_type => amount_of_mana.
		attr_reader :mana
		# Round number of current game.
		attr_reader :step
		# Player's creature field. A Ccg::Field object.
		attr_reader :field
		# Player's cards in hand. A Ccg::Hand object.
		attr_reader :hand

		# Which cards can hero play right now (hash).
		#
		# Example:
		#
		#     enabled_cards['Light'][0] - true or false
		attr_reader :enabled_cards 

		def initialize
			@enabled_cards = {}
			@mana = {}
			@field = Field.new(@mana)
			@hand = Hand.new
			@character_class = ''
			@step = 0
			@name = ''
			@hp = 50
			@max_hp = 100
			CARDS.each_key do |key|
				@mana[key] = 0
			end
			random_mana = ['Law', 'Light', 'Chaos', 'Darkness'].shuffle
			@mana[random_mana[0]] = 1 + rand(2)
			@mana[random_mana[1]] = 1
			@mana[random_mana[2]] = 1
			@mana[random_mana[3]] = rand(2)
			@mana['Psychic'] = -1
			self
		end

		# Player's character class (a string).
		def character_class=(new_class)
			@character_class = new_class
			@hand.special_class = new_class
		end

		# Starts a turn. Called automatically on 'state_*_start' states.
		def start_turn!
			# increases step counter
			@step += 1;

			# mana gain
			@mana.each_key do |key|
				self.mana_change!(1, key)
			end

			# Boost class mana every 2 turn
			mana_to_boost = case @character_class
				when 'druid' then 'Light'
				when 'paladin' then 'Law'
				when 'shinigami' then 'Darkness'
				when 'sorcerer' then 'Chaos'
			end
			self.mana_change!(1, mana_to_boost) if @step.even?

			# Check bonuses
			self.check_bonus!

			self
		end

		# Check attack bonuses. Used elsewhere.
		def check_bonus!
			# Reset all bonuses first
			@field.position.each do |slot|
				slot.reset_attack!
			end

			# Apply bonuses if any
			@field.position.each_with_index do |slot, index|
				unless slot.empty?
					slot.abilities.each do |ability|
						case ability['name']
							# +1 to attack of all ally creatures other than itself 
							when 'Enforcer'
								@field.position.each_with_index do |affected_slot, affected_index|
									unless (affected_slot.empty? || index == affected_index)
											affected_slot.boost_attack!(ability['param'].to_i)
									end
								end
						end # case
					end
				end # unless slot.empty?
			end # @field.position.each_with_index
		end

		# Increase / decrease mana of a specified type.
		def mana_change!(amount, type)
			@mana[type] += amount
			@mana[type] = 0 if @mana[type] < 0
			@mana[type] = 100 if @mana[type] > 100
			@mana['Psychic'] = 6 if @mana['Psychic'] > 6
			check_card_playability! # Recalculate which cards can be played
			self
		end

		# Increase / decrease mana for all types but 'type'.
		# 'type' is an array / other type that has include?
		def mana_change_all!(amount, type = [])
			@mana.each_key do |key|
				self.mana_change!(amount, key) unless type.include?(key)
			end
			self
		end

		# Do damage to this hero.
		def do_damage!(num, type = :normal)
			unless num <= 0 # Sanity check
				# Check abilities first (currently none).
				@hp -= num
			end
			self
		end

		# Heal this hero.
		def do_heal!(num)
			unless num <= 0 # Sanity check
				# check abilities first (currently none).
				@hp += num
				@hp = @max_hp if @hp > @max_hp
			end
			self
		end

		# Is hero destroyed?
		def destroyed?
			@hp <= 0
		end

		# Damage to hero and all his creatures.
		# Slots specified in 'restricted' are not damaged.
		def do_damage_all!(num, type = :normal, restricted = [])
			unless num <= 0 # Sanity check
				self.do_damage!(num, type)
				self.do_damage_creatures!(num, type, restricted)
			end
			self
		end

		# Damage to all hero's creatures.
		# Slots specified in 'restricted' are not damaged.
		def do_damage_creatures!(num, type = :normal, restricted = [])
			unless num <= 0 # Sanity check
				@field.position.each_with_index do |slot, index|
					slot.do_damage!(num, type) unless restricted.include?(index)
				end
			end
			self
		end

		# Heals hero and all his creatures.
		# Slots specified in 'restricted' are not healed.
		def do_heal_all!(num, restricted = [])
			unless num <= 0 # Sanity check
				self.do_heal!(num)
				self.do_heal_creatures!(num, restricted)
			end
			self
		end

		# Heals all hero's creatures.
		# Slots specified in 'restricted' are not healed.
		def do_heal_creatures!(num, restricted = [])
			unless num <= 0 # Sanity check
				@field.position.each_with_index do |slot, index|
					slot.do_heal!(num) unless restricted.include?(index)
				end
			end
			self
		end

		# Destroy this hero (HP = 0).
		def do_destroy!
			@hp = 0
		end

		# Swap mana value of type 'a' with value of type 'b'.
		def mana_swap!(a, b)
			@mana[a], @mana[b] = @mana[b], @mana[a]
			self
		end

		private

		# Checks if there is enough mana to play a card
		def check_card_playability!
			@hand.cards.each_pair do |type, value|
				enabled_cards[type] = []
				value.each_with_index do |card, index|
					enabled_cards[type].push(can_play?(card))
				end
			end
			self
		end

		# Can hero play this card?
		def can_play?(card)
			# If there is enough primary mana
			result = card['cost'].to_i <= @mana[card['base_mana_type']]
			# Special cards cost 2 additional mana to cast
			unless card['add'].nil?
				result &&= (@mana[card['add']] >= 2)
			end
			result
		end

	end
end
