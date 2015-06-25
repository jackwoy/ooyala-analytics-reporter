require './lib/appconfig'
require './lib/analyticstojson'
require './lib/analyticsv3tojson'
require 'date'
require './lib/analyticsjsontocsv'
require './lib/analyticsv3jsontocsv'

class ReportGenerator

  # Date inputs expected as string representations of dates
  def calculateDaysDifference(start_date_string, end_date_string)
    from = Date.parse(start_date_string)
    to = Date.parse(end_date_string)
    return to - from
  end

  def runReport(start_date_string, end_date_string, v2_analytics, extra_params, config_filename, output_filename, custom_metrics)
    daysDifference = calculateDaysDifference(start_date_string,end_date_string)
    config = AppConfig.new
    config_vars = {}
    config_vars = config.getConfig(config_filename)
    
    # Check whether the output folder exists. Create it if it does not.
    output_folder = config_vars['output_folder']
    if !Dir.exist?(output_folder)
      puts 'Could not find output folder. Creating it now.'
      Dir.mkdir(output_folder)
    end

    if (output_filename == nil)
      jsonFilename = "%{output}/analytics_results_%{from}-to-%{to}.json" % { output: output_folder, from:start_date_string, to:end_date_string }
      csvFilename = "%{output}/csv_analytics_results_%{from}-to-%{to}.csv" % { output: output_folder, from:start_date_string, to:end_date_string }
    else
      jsonFilename = "%{custom}.json" % { custom:output_filename }
      csvFilename = "%{custom}.csv" % { custom:output_filename }
    end

    if(v2_analytics)
      analytics = AnalyticsToJSON.new(config_vars['api_key'],config_vars['api_secret'])
      csvOut = AnalyticsJSONtoCSV.new
    else
      analytics = AnalyticsV3ToJSON.new(config_vars['api_key'],config_vars['api_secret'])
      analytics.extra_params = extra_params if(extra_params != nil)
      csvOut = AnalyticsV3JSONtoCSV.new
    end

    puts "Generating JSON"
    analytics.getReport(start_date_string,end_date_string, jsonFilename)
    puts "Parsing to CSV"
    csvOut.csvFromFile(jsonFilename,csvFilename,daysDifference.to_i+1)
    puts "Done!"
  end
end