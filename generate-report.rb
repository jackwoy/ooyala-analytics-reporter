require 'optparse'
require 'yaml'
require './lib/analyticstojson'
require './lib/analyticsv3tojson'
require 'date'
require './lib/analyticsjsontocsv'
require './lib/analyticsv3jsontocsv'

#Acquire command line optionsoptions[:secret]
options = {}
begin
  OptionParser.new do |opts|

    opts.banner = "Usage: generate-report.rb -s <start_date> -e <end_date> -o"

    opts.on("-s from_date", "Start date in ISO, e.g. 2014-01-31", :REQUIRED) do |s|
      options[:from_date] = s
    end

    opts.on("-e to_date", "End date in ISO, e.g. 2014-01-31", :REQUIRED) do |e|
      options[:to_date] = e
    end

    opts.on("-o", "--old", "Use v2 analytics") do
      options[:v2_analytics] = true
    end
  end.parse!
rescue OptionParser::InvalidOption => s
  puts s
  exit(1)
rescue OptionParser::MissingArgument => e
  puts e
  exit(1)
end
if !options.has_key?(:from_date)
  puts "From Date is required"
  exit(1)
elsif !options.has_key?(:to_date)
  puts "To Date is required"
  exit(1)
end

if !options.has_key?(:v2_analytics)
  options[:v2_analytics] = false
end

# Hacky way of handling custom config. Mainly done for repository management purposes to reduce likelihood of API credentials being committed.
# System will use config.local.yaml (which isn't checked in) preferentially to config.yaml (which is).
def get_config()
  configFilename = ""
  if File.exist?('config.local.yaml')
    configFilename = 'config.local.yaml'
  else
    configFilename = 'config.yaml'
  end
  return YAML.load_file(configFilename)
end

def calculate_days_difference(start_date_string, end_date_string)
  from = Date.parse(start_date_string)
  to = Date.parse(end_date_string)
  return to - from
end

def run_report(start_date_string, end_date_string, v2_analytics)
  config_vars = get_config()
  # Check whether the output folder exists. Create it if it does not.
  output_folder = config_vars['output_folder']
  if !Dir.exist?(output_folder)
    puts 'Could not find output folder. Creating it now.'
    Dir.mkdir(output_folder)
  end

  jsonFilename = "%{output}/analytics_results_%{from}-to-%{to}.json" % { output: output_folder, from:start_date_string, to:end_date_string }
  csvFilename = "%{output}/csv_analytics_results_%{from}-to-%{to}.csv" % { output: output_folder, from:start_date_string, to:end_date_string }

  if(v2_analytics)
    analytics = AnalyticsToJSON.new(config_vars['api_key'],config_vars['api_secret'])
    csvOut = AnalyticsJSONtoCSV.new
  else
    analytics = AnalyticsV3ToJSON.new(config_vars['api_key'],config_vars['api_secret'])
    csvOut = AnalyticsV3JSONtoCSV.new
  end
  puts "Generating JSON"
  analytics.runReport(start_date_string,end_date_string, jsonFilename)

  daysDifference = calculate_days_difference(start_date_string,end_date_string)

  puts "Parsing to CSV"
  csvOut.csvFromFile(jsonFilename,csvFilename,daysDifference.to_i+1)
  puts "Done!"
end

run_report(options[:from_date],options[:to_date],options[:v2_analytics])