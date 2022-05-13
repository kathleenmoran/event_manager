require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  digits_only = phone_number.to_s.tr('^0-9', '')
  if digits_only.length == 10
    digits_only
  elsif phone_number.to_s.length == 11 && phone_number.to_s[0] == 1
    digits_only[1..]
  else
    '0000000000'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hour_freqs = Hash.new(0)
registration_day_freqs = Hash.new(0)
puts 'Phone numbers:'
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  date_and_hour = DateTime.strptime(row[:regdate], "%m/%d/%Y %H")

  puts phone_number
  registration_hour_freqs[date_and_hour.hour] += 1
  registration_day_freqs[Date::DAYNAMES[date_and_hour.wday]] += 1

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "Peak registration hour: #{registration_hour_freqs.key(registration_hour_freqs.values.max)}"
puts "Peak registration day: #{registration_day_freqs.key(registration_day_freqs.values.max)}"