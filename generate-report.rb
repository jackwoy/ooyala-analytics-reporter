require 'optparse'
require './lib/reportgenerator'

#Acquire command line options
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

reporter = ReportGenerator.new
reporter.runReport(options[:from_date],options[:to_date],options[:v2_analytics])