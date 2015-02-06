require 'optparse'
require './lib/analyticstojson'

#Acquire command line optionsoptions[:secret]
options = {}
begin
  OptionParser.new do |opts|

    opts.banner = "Usage: generate-report.rb -s <start_date> -e <end_date>"

    opts.on("-s from_date", "Start date in ISO, e.g. 2014-01-01", :REQUIRED) do |s|
      options[:from_date] = s
    end

    opts.on("-e to_date", "End date in ISO, e.g. 2014-01-01", :REQUIRED) do |e|
      options[:to_date] = e
    end
  end.parse!
rescue OptionParser::InvalidOption => e
  puts e
  exit(1)
rescue OptionParser::MissingArgument => m
  puts m
  exit(1)
end
if !options.has_key?(:from_date)
  puts "From Date is required"
  exit(1)
elsif !options.has_key?(:to_date)
  puts "To Date is required"
  exit(1)
end

instance = AnalyticsToJSON.new
instance.runReport(options[:from_date],options[:to_date])