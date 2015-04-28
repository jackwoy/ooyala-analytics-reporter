require 'yaml'
require './lib/analyticstojson'
require './lib/analyticsv3tojson'
require 'date'
require './lib/analyticsjsontocsv'
require './lib/analyticsv3jsontocsv'

class ReportGenerator

  # Hacky way of handling custom config. Mainly done for repository management purposes to reduce likelihood of API credentials being committed.
  # System will use config.local.yaml (which isn't checked in) preferentially to config.yaml (which is).
  def getConfig()
    config_filename = ""
    if File.exist?('config.local.yaml')
      config_filename = 'config.local.yaml'
    else
      config_filename = 'config.yaml'
    end
    if !validateConfig(config_filename)
      puts "Specified config file %{filename} failed validation." % {filename: config_filename}
      exit(2)
    end
    return YAML.load_file(config_filename)
  end

  # Date inputs expected as string representations of dates
  def calculateDaysDifference(start_date_string, end_date_string)
    from = Date.parse(start_date_string)
    to = Date.parse(end_date_string)
    return to - from
  end

  def runReport(start_date_string, end_date_string, v2_analytics, extra_params)
    daysDifference = calculateDaysDifference(start_date_string,end_date_string)
    config_vars = getConfig()
    
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
      analytics.extra_params = extra_params if(extra_params != nil)
      csvOut = AnalyticsV3JSONtoCSV.new
    end

    puts "Generating JSON"
    analytics.getReport(start_date_string,end_date_string, jsonFilename)
    puts "Parsing to CSV"
    csvOut.csvFromFile(jsonFilename,csvFilename,daysDifference.to_i+1)
    puts "Done!"
  end

  def validateConfig(config_filename)
    config_is_valid = true
    # Check config file exists
    if !File.exist?(config_filename)
      puts "Specified config file %{filename} not found." % {filename: config_filename}
      config_is_valid = false
      # Return here, as running the rest of the tests is nonsensical without a config file available.
      return config_is_valid
    end

    # FIXME: Could do with removing duplicated effort of reading the config file.
    config_hash = YAML.load_file(config_filename)

    required_keys = ["api_key","api_secret","output_folder"]

    # Check for presence of required config fields
    required_keys.each_index {|i|
      if !config_hash.keys.include?(required_keys[i])
        puts i
        puts "Missing required key %{key}" % {key: required_keys[i]}
        config_is_valid = false
      end
    }
    # Bail out early if we're missing required keys.
    return config_is_valid if !config_is_valid

    # Validate API key (34 chars long)
    if config_hash["api_key"].length != 34
      puts "API key is not valid - incorrect length."
      config_is_valid = false
    end

    # Validate API secret (40 chars long)
    if config_hash["api_secret"].length != 40
      puts "API secret is not valid - incorrect length."
      config_is_valid = false
    end

    return config_is_valid
  end
end