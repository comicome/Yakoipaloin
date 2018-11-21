require 'rubygems'
require 'nokogiri' 
require 'open-uri'
require 'json/ext'


doc = Nokogiri::HTML(open("https://www.tripadvisor.fr/RestaurantSearch?Action=AVAIL_CLEAR&geo=187147&ajax=1&zfp=10598%2C10601&zfn=7236772&itags=10591&sortOrder=relevance&availSearchEnabled=true&eaterydate=2018_11_20&date=2018-11-21&time=20%3A00%3A00&people=2"), nil, Encoding::UTF_8.to_s)

restaurants_list = []

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
    end
end
puts restaurants_list.to_json

File.open("data/tripAdvisor.json","w") do |f|
    f.write(restaurants_list.to_json)
  end

