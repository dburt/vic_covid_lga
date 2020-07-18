#!/usr/bin/env ruby -w

require 'rubygems'
require 'bundler'

Bundler.require

require 'date'
require 'csv'
require 'net/http'
require 'uri'

# https://www.dhhs.vic.gov.au/coronavirus-update-victoria-11-june-2020
url_template = "https://www.dhhs.vic.gov.au/coronavirus-update-victoria-%s"
date_formats = [
    "%d-%B-%Y",      # 01-june-2020
    "%-d-%B-%Y",     # 1-june-2020
    "%A-%-d-%B",     # monday-1-june
    "%A-%d-%B",      # monday-01-june
    "%A-%-d-%B-%Y",  # monday-1-june-2020
    "%A-%d-%B-%Y",   # monday-01-june-2020
]
dates = Date.new(2020, 6, 11) .. Date.today

html_path_template = "./html/coronavirus-update-victoria-%s.html"
csv_path_template = "./csv/%s.csv"

last_total_for_lga = Hash.new { 0 }

dates.each do |date|
    html_path = html_path_template % date.to_s
    csv_path = csv_path_template % date.to_s

    if File.exist?(html_path)
        html = File.read(html_path)
    else
        urls = date_formats.map {|fmt| url_template % date.strftime(fmt).downcase }.uniq
        urls.each do |url|
            html = Net::HTTP.get(URI(url))
            break if html !~ /Error\<\/title\>/
        end
        File.open(html_path, 'w') do |f|
            f.write html
        end
    end

    doc = Nokogiri::HTML(html)
    page_title = doc.css('title').text.strip
    if page_title =~ /\| Error$/
        STDERR.puts "warning: #{html_path} is an error page"
        File.unlink(html_path)
        next
    end

    table = doc.css('table')
    if table.length != 1
        STDERR.puts "warning: #{date} has #{table.length} tables"
        next
    end
    data = []
    table.css('tr').each do |tr|
        data << tr.css('th, td').map do |td|
            td.text.gsub(/[[:space:]]/, ' ').strip.titlecase.chomp(':')
        end
    end

    CSV.open(csv_path, 'w') do |csv|
        data.each do |row|
            csv << row
        end
    end
end

output_path = "coronavirus cases by vic lga #{dates.last.to_s}.csv"
count = 0
CSV.open(output_path, 'w') do |csv|
    csv << %w(date lga_name total_cases active_cases new_cases)

    dates.each do |date|
        csv_path = csv_path_template % date.to_s

        csv_data = CSV.read(csv_path) rescue next
        headers = csv_data.shift
        headers = csv_data.shift if headers[0] =~ /Confirmed cases by LGA/i
        unless headers[0] =~ /LGA/i &&
               headers[1] =~ /confirmed cases/i && headers[1] =~ /ever/i &&
               headers[2] =~ /active cases/i && headers[2] =~ /current/i
            STDERR.puts "warning: unexpected headers in #{csv_path}"
            next
        end
        csv_data.each do |lga_name, total_cases, active_cases|
            csv << [date, lga_name, total_cases, active_cases,
                    total_cases.to_i - last_total_for_lga[lga_name]]
            count += 1
            last_total_for_lga[lga_name] = total_cases.to_i
        end
    end
end
puts "Wrote #{count} records to #{output_path}"
