require 'rubygems'
require 'nokogiri' 
require 'open-uri'
require 'json/ext'
require 'csv'

def parse_restaurants(nombreRestaurants, restaurants_list)

    url = "https://www.tripadvisor.fr/RestaurantSearch?Action=PAGE&geo=187147&ajax=1&zfp=10598,10601&zfn=7236772&itags=10591&sortOrder=relevance&o=a#{nombreRestaurants}&availSearchEnabled=true&time=12:00:00"
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)

    doc.css("div.listing").each do |restaurant|
        types_list = []
        if restaurant.css('div.title a').text != ''

            rating = restaurant.css('div.rating span').to_s.match(/_(\d+)/)
            url_restaurant = 'https://www.tripadvisor.fr' + restaurant.css('a.photo_link')[0]["href"]

            puts url_restaurant
            restaurant.css('a.item.cuisine').each do |cuisine|
                type = cuisine.text
                types_list << type
            end

            restaurant = {
                "name" => restaurant.css('div.title a').text.gsub("\n", ''),
                "image" => restaurant.css("img.photo_image")[0]["src"],
                "reviewCount" => restaurant.css('span.reviewCount a').text.gsub("\n", '').gsub(" avis ", '').to_i,
                "rating" => rating[1..-1].first.to_f/10,
                "price" => restaurant.css('span.item.price').text,
                "type_list" => types_list,
                'address' => get_address(url_restaurant),
                'link' => url_restaurant,
                "source" => "Tripadvisor"
            }
            puts restaurant
            restaurants_list << restaurant
            nombreRestaurants += 1
            puts nombreRestaurants
        end
    end
    if nombreRestaurants % 30 == 0
        parse_restaurants(nombreRestaurants, restaurants_list)
    end
    return restaurants_list
end

def get_address(url)
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)
    address = doc.css('div.blEntry.address').text
    return address
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