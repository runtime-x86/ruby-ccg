# encoding: utf-8
#
# License: GPL v3 or any later version, http://www.gnu.org/licenses/gpl-3.0.txt
#
# Author: Tenno Seremel, http://serenareem.net/html/other/ruby-ccg.xml
#
# Version: 0.2

require 'json'

if RUBY_VERSION < '1.9'
	class Array
		# .sample was called .choice before 1.9
		alias_method :sample, :choice
	end
end

module Ccg
	VERSION = '0.2' # Game version
	@@lib_path = File.dirname(File.expand_path(__FILE__))
	@@data_path = File.expand_path("#{@@lib_path}/../../share/ruby-ccg")

	# Holds all card/class data.
	@@classes = JSON::parse(IO.read(File.join(@@data_path, 'classes.json')))['classes']

	# Loads JSON file with card data.
	@@cards = JSON::parse(IO.read(File.join(@@data_path, 'cards.json')))

	# Set mana type for each card...
	@@cards.each_pair do |card_type, card_list|
		card_list.each do |card|
			card['base_mana_type'] = card_type
		end
	end

	# Contains character class names available to player.
	#
	# An array: [class_name_1, class_name_2...]
	def self::classes
		@@classes
	end

	# Contains info about all cards by type.
	#
	# A hash: type => [card_1, card2...]
	def self::cards
		@@cards
	end

	require "#{@@lib_path}/ccg-state.rb"
	require "#{@@lib_path}/ccg-hand.rb"
	require "#{@@lib_path}/ccg-slot.rb"
	require "#{@@lib_path}/ccg-field.rb"
	require "#{@@lib_path}/ccg-hero.rb"
	require "#{@@lib_path}/ccg-game.rb"

end # module Ccg
