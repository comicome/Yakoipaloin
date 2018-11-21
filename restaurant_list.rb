require 'rubygems'
require 'nokogiri' 
require 'open-uri'
require 'json/ext'
require 'csv'

def parse_restaurants(nombreRestaurants, restaurants_list)

    url = "https://www.tripadvisor.fr/RestaurantSearch?Action=PAGE&geo=187147&ajax=1&zfp=10598,10601&zfn=7236772&itags=10591&sortOrder=relevance&o=a#{nombreRestaurants}&availSearchEnabled=true&time=12:00:00"
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)

    doc.css("div.listing div.ui_column").each do |restaurant|
        types_list = []
        if restaurant.css('div.title a').text != ''

            rating = restaurant.css('div.rating span').to_s.match(/_(\d+)/)

            restaurant.css('a.item.cuisine').each do |cuisine|
                type = cuisine.text
                types_list << type
            end

            restaurant = {
                "name" => restaurant.css('div.title a').text.gsub("\n", ''),
                "reviewCount" => restaurant.css('span.reviewCount a').text.gsub("\n", '').gsub(" avis ", '').to_i,
                "price" => restaurant.css('span.item.price').text,
                "type_list" => types_list,
                "rating" => rating[1..-1].first.to_f/10,
                "source" => "Tripadvisor"
            }
            restaurants_list << restaurant
            nombreRestaurants += 1
        end
    end
    if nombreRestaurants % 30 == 0
        parse_restaurants(nombreRestaurants, restaurants_list)
    end
    return restaurants_list
end


def hash_to_json_file (restaurants_list)
    File.open("data/tripAdvisor.json","w") do |f|
        f.write(restaurants_list.to_json)
    end
end


def hash_to_csv_file (restaurants_list)
    column_names = restaurants_list.first.keys
    s=CSV.generate do |csv|
        csv << column_names
        restaurants_list.each do |x|
            csv << x.values
        end
    end
    File.write('data/tripAdvisor.csv', s)
end


hash_to_convert = parse_restaurants(0, [])

hash_to_csv_file(hash_to_convert)
hash_to_json_file(hash_to_convert)