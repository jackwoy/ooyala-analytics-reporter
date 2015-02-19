Shoes.setup do
  gem 'rest-client'
end
require 'optparse'
require 'yaml'
require './lib/analyticstojson'
require 'date'
require './lib/analyticsjsontocsv'

Shoes.app title: "Ooyala Analytics Report Generator" do
  @root_stack = stack do
    flow do
      para "Start Date"
      @start_date = edit_line
    end
    flow do
      para "End Date"
      @end_date = edit_line
    end

    # TODO: Implement progress bar.
    #@p = progress width: 1.0
    
    # TODO: Use change handler for start date and end date to enable this button once we have valid dates?
    @report_button = button "Generate Report"
    
    @report_button.click do
      # FIXME: Very basic input checking. Make sure we've been given a date in YYYY-MM-DD format.
      # FIXME: Need to test for things like start date being before end date.
      if !validate_date_input?(@start_date.text())
        # FIXME: Don't raise so many alerts. :(
        alert("Start date is not a valid date.")
        return
      end
      if !validate_date_input?(@end_date.text())
        alert("End date is not a valid date.")
        return
      end
      alert("Generating Report")
      run_report(@start_date.text(), @end_date.text())
      alert("Done!")
    end
    # Sample progress bar animation code
    # TODO: Implement progress bar.
    #animate do |i|
    #   @p.fraction = (i % 100) / 100.0
    #end
  end
end

def validate_date_input?(date_as_string)
  y, m, d = date_as_string.split("-")
  return Date.valid_date?(y.to_i, m.to_i, d.to_i)
end

# Date inputs expected as string represen
def calculate_days_difference(start_date_string, end_date_string)
  from = Date.parse(start_date_string)
  to = Date.parse(end_date_string)
  return to - from
end
# startDate, endDate are expected to be string representations of dates
# TODO: Split up this method into a few methods.
def run_report(startDate, endDate)
  # Hacky way of handling custom config. Mainly done for repository management purposes to reduce likelihood of API credentials being committed.
  # System will use config.local.yaml (which isn't checked in) preferentially to config.yaml (which is).
  configFilename = ""
  if File.exist?('config.local.yaml')
    configFilename = 'config.local.yaml'
  else
    configFilename = 'config.yaml'
  end
  config_vars = YAML.load_file(configFilename)

  # Could load output filenames from config. Or prompt user to save CSV instead.
  jsonFilename = "output/analytics_results_%{from}-to-%{to}.json" % { from:startDate, to:endDate }
  csvFilename = "output/csv_analytics_results_%{from}-to-%{to}.csv" % { from:startDate, to:endDate }
  analytics = AnalyticsToJSON.new(config_vars['api_key'],config_vars['api_secret'])
  analytics.runReport(startDate,endDate, jsonFilename)
  daysDifference = calculate_days_difference(startDate, endDate)
  csvOut = AnalyticsJSONtoCSV.new
  csvOut.csvFromFile(jsonFilename,csvFilename,daysDifference.to_i+1)
end