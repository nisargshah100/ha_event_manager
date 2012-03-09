require "csv"
require "sunlight"

class EventManager
  INVALID_ZIPCODE = "00000"
  HEADING_LINE_CSV = 2
  VALID_PHONE_NUMBER_LENGTH = 10
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def initialize(filename)
    puts "EventManager Initialized."
    @file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
  end

  def print_names
    @file.each do |line|
      puts "#{line[:first_name]} #{line[:last_name]}"
    end
  end

  def print_numbers
    @file.each do |line|
      puts clean_number(line[:homephone])
    end
  end

  def clean_number(original)
    cleaned = original.gsub(/-|\.|\s|\(|\)/, '')

    if cleaned.length == VALID_PHONE_NUMBER_LENGTH
      cleaned
    elsif cleaned.length == VALID_PHONE_NUMBER_LENGTH+1 && cleaned[0] == 1
      cleaned[1..-1]
    else
      nil
    end
  end

  def print_zipcodes
    @file.each do |line|
      zipcode = clean_zipcode(line[:zipcode])
      puts zipcode
    end
  end

  def clean_zipcode(original)
    zip = ("%05d" % (original || 0))
    zip unless zip == INVALID_ZIPCODE
  end

  def output_data(filename)
    output = CSV.open(filename, "w")
    @file.each do |line|
      if @file.lineno == HEADING_LINE_CSV
        output << line.headers
      else
        line[:homephone] = clean_number(line[:homephone])
        line[:zipcode] = clean_zipcode(line[:zipcode])
        output << line
      end
    end
  end

  def rep_lookup
    20.times do
      line = @file.readline
      
      legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
      names = legislators.collect do |leg|
        first_name = leg.firstname
        first_initial = first_name[0]
        last_name = leg.lastname
        first_initial + ". " + last_name
      end

      puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
    end
  end

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do
      line = @file.readline

      custom_letter = letter.gsub("#first_name", line[:first_name])
      custom_letter = custom_letter.gsub("#last_name", line[:last_name])
      custom_letter = custom_letter.gsub("#city", line[:city])
      custom_letter = custom_letter.gsub("#state", line[:state])
      custom_letter = custom_letter.gsub("#zipcode", line[:zipcode]) 
      custom_letter = custom_letter.gsub("#street", line[:street])

      filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
      output = File.new(filename, "w")
      output.write(custom_letter)
    end
  end

  def rank_times
    hours = Array.new(24){0}
    @file.each do |line|
      hour = line[:regdate]
      hour = hour.split[1].split(":")[0].to_i
      hours[hour] += 1
    end
    hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
  end

end

manager = EventManager.new("event_attendees.csv")
manager.create_form_letters