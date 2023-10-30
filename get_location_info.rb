require 'dotenv'
require 'net/http'
require 'json'
require 'uri'
require 'colorize'

# Load environment variables from .env file
Dotenv.load

# Now you can use your API key
GOOGLE_MAPS_API_KEY = ENV['GOOGLE_MAPS_API_KEY']

puts 'Getting location info...'

def get_user_ip
  uri = URI('https://api.ipify.org?format=json')
  response = Net::HTTP.get(uri)
  raise 'Error: Could not get user IP address' unless response

  JSON.parse(response)['ip']
end

def get_geolocation_info(ip)
  uri = URI("http://ip-api.com/json/#{ip}")
  response = Net::HTTP.get(uri)
  raise 'Error: Could not get location info' unless response

  JSON.parse(response)
end

def get_nearby_places(lat, lon)
  places_uri = URI("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{lat},#{lon}&radius=500&type=restaurant&key=#{GOOGLE_MAPS_API_KEY}")
  response = Net::HTTP.get(places_uri)
  raise 'Error: Could not get places info' unless response

  places_data = JSON.parse(response)
  raise "Error from Places API: #{places_data['error_message']}" if places_data['status'] != 'OK'

  places_data
end

def display_places(places)
  puts "\nNearby Restaurants:".colorize(:cyan)
  places.each_with_index do |place, index|
    rating = place['rating'] ? "Rating: #{place['rating']}/5" : 'Rating: N/A'
    puts "#{index + 1}: #{place['name']} - #{rating}".colorize(:light_blue)
  end
end

def user_select_place(places)
  puts "\nSelect a place by number for more details, or type 'exit' to quit:"
  input = gets.chomp
  return if input.downcase == 'exit'

  selected_index = input.to_i - 1
  if selected_index.between?(0, places.size - 1)
    places[selected_index]
  else
    puts "Invalid selection. Please enter a valid number or type 'exit'."
    nil
  end
end

def show_place_details(place)
  return puts 'Sorry, this place is permanently closed.'.colorize(:red) if place['permanently_closed'] == true

  puts "\nDetails for: #{place['name']}"
  puts "Address: #{place['vicinity']}"
  if place.key?('rating') && place.key?('user_ratings_total')
    puts "Rating: #{place['rating'] || 'N/A'} based on #{place['user_ratings_total']} review(s)"
  end
  puts "Location type: #{place['types'].include?('restaurant') ? place['types'][0] : 'Various'}" if place.key?('types')
  puts "Status: #{place['business_status']}" if place['business_status']
end

user_ip = get_user_ip
geo_data = get_geolocation_info(user_ip)
geo_data.each { |key, value| puts "#{key.capitalize}: #{value}" }

goolge_places_data = get_nearby_places(geo_data['lat'], geo_data['lon'])
display_places(goolge_places_data['results'])

selected_place = nil
selected_place = user_select_place(goolge_places_data['results']) until selected_place

show_place_details(selected_place) if selected_place
