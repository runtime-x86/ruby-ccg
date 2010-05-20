# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2-1

module Ccg
	# Represents the whole field of a player (i.e. group of slots).
	class Field
		# Slots: asumming vertical layout. Is an array.
		attr_reader :position

		def initialize(mana)
			@position = []
			6.times { @position.push(Slot.new(mana)) }
			self
		end

		# Is field empty?
		def empty?
			result = true
			@position.each do |slot|
				result &&= slot.empty?
			end
			result
		end

		# Can switch slots on a field. Unused for now.
		def switch!(a, b)
			@position[a], @position[b] = @position[b], @position[a]
			self
		end
	end
end
