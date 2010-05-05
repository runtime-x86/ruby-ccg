# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2

module Ccg
	# Represents creature slot on a battlefield.
	class Slot
		attr_reader :hp, :base_attack, :attack, :cost, :max_hp, :name
		attr_reader :abilities, :card_type, :base_mana_type

		def initialize(mana)
			@owner_mana = mana
			self.reset!
			self
		end

		# Slot is now empty.
		def reset!
			@card = nil
			@abilities = nil
			@hp = 0
			@base_attack = 0
			@attack = 0
			@cost = 0
			@max_hp = 0
			@name = ''
			@card_type = ''
			@base_mana_type = ''
			self
		end

		# Assign some creature to this slot.
		def assign!(card)
			# Card data (for abilities and actions).
			@card = card

			# Setting cost.
			@cost = card['cost'].to_i

			# Setting attack.
			@attack = @base_attack = card['attack'].to_i

			# Setting hp.
			@max_hp = card['hp'].to_i
			@max_hp = 1 if @max_hp == 0
			@hp = @max_hp

			# Set name
			@name = card['name'].to_s

			# Link to card abilities
			@abilities = card['abilities']

			@card_type = card['type'].to_s

			@base_mana_type = card['base_mana_type'].to_s

			self
		end

		def boost_attack!(amount)
			@attack += amount
		end

		def reset_attack!
			@attack = @base_attack
		end

		# Deal specified amount of damage to this slot.
		# It checks some abilities and call do_destroy if there is no HP left.
		# types are :normal and :magic
		def do_damage!(num, type = :normal)
			return self if (self.empty? || num <= 0) # Do nothing if slot is empty

			# Check abilities first and calculate actual damage.
			actual_damage = num
			@abilities.each do |ability|
				case ability['name']
					when 'Deathless'
						actual_damage = 0 if @owner_mana['Darkness'] >= 10
					when 'Magic proof'
						# Half damage if magic damage.
						actual_damage /= 2 if type == :magic
					when 'Resistant'
						# Reduce damage by @param value.
						actual_damage -= ability['param'].to_i
					when 'Spell immunity'
						# Zero damage if magical.
						actual_damage = 0 if type == :magic
				end
			end
			@hp -= actual_damage
			self.do_destroy! if @hp <= 0
			self
		end

		# Restores specified amount of HP to this slot.
		# HP cannot become more than Max HP as a result.
		def do_heal!(num)
			unless self.empty? || num <= 0 # Do nothing if slot is empty.
				# Check abilities first (currently none).
				@hp += num
				@hp = @max_hp if @hp > @max_hp
			end
			self
		end

		# Creature in this slot is destroyed and slot is now empty.
		def do_destroy!
			unless self.empty? # Do nothing if slot is empty
				# Check 'on destroy abilities' (currently none) then reset.
				self.reset!
			end
			self
		end

		# Is this slot empty?
		def empty?
			return @card.nil?
		end
	end
end
