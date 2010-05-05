# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2

module Ccg
	# Cards in hand.
	class Hand
		# Cards in this hand. A hash: type => [card_1, card_2, ...]
		attr_reader :cards
		# Player's character class.
		attr_accessor :special_class

		def initialize
			@cards = {}
			@special_class = nil
			self
		end

		# Get random cards.
		# If there was something in hand... too bad now it's gone.
		def shuffle!
			unless @special_class.nil?
				Ccg::cards.each_pair do |key, value| #each group of cards
					group_length = value.length
					@cards[key] = []
					if group_length < 5
						# If there is less than 5 cards of current type
						# - add them all.
						@cards[key] = value
					else
						# Otherwise calculate.
						if key == 'Psychic'
							# "Psychic" requires special treatment.

							# Add 3 class cards.
							@cards[key].concat(value.reject { |item|
								!item['primary'].nil? && item['primary'] != @special_class
							}.shuffle.first(3))

							# Add 1 non-class card.
							@cards[key].push(value.reject { |item|
								!item['primary'].nil? && item['primary'] == @special_class
							}.choice)
						else
							# Normal card selection (1 per 4 cards).
							x = group_length / 4
							3.times do |y|
								new_card = y*x + rand(x)
								@cards[key].push(value[new_card])
							end
							last_card = 3*x + rand(group_length - 3*x)
							@cards[key].push(value[last_card])
						end
					end
				end
			end
			self
		end
	end
end
