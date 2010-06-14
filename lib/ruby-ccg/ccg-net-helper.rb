# encoding: UTF-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2-2
#
# Do not use...
# :enddoc:

require 'ccg-base'

module Ccg
	class Hero
		# Returns a Hash.
		# Hash['type'] - Array of card names hero has of 'type' type.
		def net_hand_data
			card_names = {}
			@hand.cards.each_pair do |key, value|
				card_names[key] = []
				value.each do |card|
					card_names[key] << card['name']
				end
			end
			card_names
		end
	end

	class Hand
		# Sets cards of 'type' type in hand, card_names is an Array of names.
		# Raises TypeError if card_names is not an Array.
		# Raises exception if card_names is empty.
		# Raises exception if any card was not found in local data.
		def net_set_cards(type, card_names)
			raise(TypeError, 'card_names parameter should be an Array.') unless card_names.instance_of?(Array)
			raise('card_names parameter is empty.') if card_names.empty?

			@cards[type] = []

			card_names.slice(0..4).each do |card_name|
				found = CARDS[type].index{ |x| x['name'] == card_name }
				if found.nil?
					raise "Card '#{card_name}' was not found. You can't really continue net game."
				else
					@cards[type] << found unless found.nil?
				end
			end

			self
		end
	end

end
