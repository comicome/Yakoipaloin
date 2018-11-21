require 'rubygems'
require 'nokogiri' 
require 'open-uri'
require 'json/ext'
require 'csv'

def parse_restaurants_trip_advisor(nombreRestaurants, restaurants_list)
    url = "https://www.tripadvisor.fr/RestaurantSearch?Action=PAGE&geo=187147&ajax=1&zfp=10598,10601&zfn=7236772&itags=10591&sortOrder=relevance&o=a#{nombreRestaurants}&availSearchEnabled=true&time=12:00:00"
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)

    doc.css("div.listing").each do |restaurant|
        types_list = []
        source = "Tripadvisor"
        if restaurant.css('div.title a').text != ''

            rating = restaurant.css('div.rating span').to_s.match(/_(\d+)/)
            url_restaurant = 'https://www.tripadvisor.fr' + restaurant.css('a.photo_link')[0]["href"]

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
                "source" => source
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

def parse_restaurants_deliveroo(restaurants_list)
    url = "https://deliveroo.fr/fr/restaurants/paris/10eme-gare-du-nord?geohash=u09wj98ze9hc"
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)

    doc.css("li.RestaurantsList-f37d5282571072cb").each_with_index do |restaurant, index|
        types_list = []
        source  = "Deliveroo"

        rating = restaurant.css('span.ccl-19882374e640f487.ccl-417df52a76832172.ccl-a6fe14df36a14ee6').text.to_f
        rating = rating/20

        url_restaurant = restaurant.css('div.RestaurantCard-4ed7f323d018d7ae a')[0]["href"]
        restaurant_details = get_restaurant_details(url_restaurant)

        avis = restaurant.css('div[class^="Rating-"] span.ccl-19882374e640f487.ccl-417df52a76832172.ccl-dfaaa1af6c70149c').text
        avis = avis.gsub("(","").gsub("+)","").to_i

        restaurant = {
            "name" => restaurant.css('p.ccl-19882374e640f487.ccl-417df52a76832172.ccl-a5fb02a1085896d3.ccl-dd90031787517421.ccl-c9da0519c26dc749').text,
            "image" => restaurant_details["image"],
            "reviewCount" => avis,
            "rating" => rating,
            "price" => restaurant.css('span.ccl-19882374e640f487.ccl-417df52a76832172.ccl-dfaaa1af6c70149c span.TagList-7cda8f30b4344d40')[0].text,
            "type_list" => restaurant_details["types"],
            'address' => restaurant_details["image"],
            'link' => url_restaurant,
            "source" => source
        }
        restaurants_list << restaurant
        break if index > 10
    end

    return restaurants_list 
end

def get_address(url)
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)
    address = doc.css('div.blEntry.address').text
    return address
end

def get_restaurant_details(url)
    types_list = []
    doc = Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)
    address = doc.css('small.address').text
    img = doc.css('div.restaurant__image')[0]["style"].gsub("background-image:url(", '').gsub(");", '')

    doc.css('small.restaurant__metadata-tags small').each do |cuisine|
        type = cuisine.text
        types_list << type
    end

    {"image" => img, "address" => address, "types" => types_list}
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

puts "TripAdvisor is starting"
hash_to_convert = parse_restaurants_trip_advisor(0, [])
puts "TripAdvisor has ended, Deliveroo is starting"
hash_to_convert = parse_restaurants_deliveroo(hash_to_convert)
puts "Deliveroo has ended"

puts "JSON export is starting"
hash_to_csv_file(hash_to_convert)
puts "Export JSON has ended, CSV export is starting"
hash_to_json_file(hash_to_convert)
puts "Export CSV has ended"