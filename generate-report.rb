require 'optparse'
require './lib/reportgenerator'

#Acquire command line options
options = {}
begin
  OptionParser.new do |opts|
    options[:v2_analytics] = false

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

    opts.on("-p extra_params", "--params", "Include extra parameters. Cannot be used with v2 analytics.") do |p|
      options[:extra_params] = p
    end

    opts.on("-c custom_config", "--config", "Specify a config file.") do |c|
      options[:config] = c
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

if options.has_key?(:config) && !File.exist?(options[:config])
  puts "Specified config file %{filename} not found." % {filename: options[:config]}
  exit(1)
end

if options[:v2_analytics] && options.has_key?(:extra_params)
  puts "Cannot include extra parameters in V2 analytics."
  exit(1)
end

reporter = ReportGenerator.new
# FIXME: Should probably refactor this. Adding more arguments to the runReport method isn't a great way of doing things.
reporter.runReport(options[:from_date],options[:to_date],options[:v2_analytics],options[:extra_params],options[:config])