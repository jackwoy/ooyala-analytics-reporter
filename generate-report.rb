require 'optparse'
require 'yaml'
require './lib/analyticstojson'
require './lib/analyticsv3tojson'
require 'date'
require './lib/analyticsjsontocsv'

#Acquire command line optionsoptions[:secret]
options = {}
begin
  OptionParser.new do |opts|

    opts.banner = "Usage: generate-report.rb -s <start_date> -e <end_date> -o"

    opts.on("-s from_date", "Start date in ISO, e.g. 2014-01-01", :REQUIRED) do |s|
      options[:from_date] = s
    end

    opts.on("-e to_date", "End date in ISO, e.g. 2014-01-01", :REQUIRED) do |e|
      options[:to_date] = e
    end

    opts.on("-o", "--old", "Use v2 analytics") do
      options[:v2_analytics] = true
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
jsonFilename = "output/analytics_results_%{from}-to-%{to}.json" % { from:options[:from_date], to:options[:to_date] }
csvFilename = "output/csv_analytics_results_%{from}-to-%{to}.csv" % { from:options[:from_date], to:options[:to_date] }
# Hacky way of handling custom config. Mainly done for repository management purposes to reduce likelihood of API credentials being committed.
# System will use config.local.yaml (which isn't checked in) preferentially to config.yaml (which is).
configFilename = ""
if File.exist?('config.local.yaml')
  configFilename = 'config.local.yaml'
else
  configFilename = 'config.yaml'
end
config_vars = YAML.load_file(configFilename)

if(options[:v2_analytics])
  analytics = AnalyticsToJSON.new(config_vars['api_key'],config_vars['api_secret'])
else
  analytics = AnalyticsV3ToJSON.new(config_vars['api_key'],config_vars['api_secret'])
end
puts "Generating JSON"
analytics.runReport(options[:from_date],options[:to_date], jsonFilename)

from = Date.parse(options[:from_date])
to = Date.parse(options[:to_date])

daysDifference = to - from

csvOut = AnalyticsJSONtoCSV.new
puts "Parsing to CSV"
if(options[:v2_analytics])
  csvOut.csvFromFile(jsonFilename,csvFilename,daysDifference.to_i+1)
else
  puts "Not implemented!"
end
puts "Done!"