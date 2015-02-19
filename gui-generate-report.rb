Shoes.setup do
  gem 'rest-client'
end
require 'optparse'
require 'yaml'
require './lib/analyticstojson'
require 'date'
require './lib/analyticsjsontocsv'

Shoes.app title: "Ooyala Analytics Report Generator", width: 400, height: 200, resizable: false do
  current_date = DateTime.now
  @root_stack = stack do
    para "Start Date"
    flow do
      @start_day_box = list_box items: (1..31).to_a, width:60, choose: current_date.day.to_i
      @start_month_box = list_box items: (1..12).to_a, width:60, choose: current_date.month.to_i
      @start_year_box = list_box items: (2013..current_date.year.to_i).to_a, width:100, choose: current_date.year.to_i
    end
    para "End Date"
    flow do 
      @end_day_box = list_box items: (1..31).to_a, width:60, choose: current_date.day.to_i
      @end_month_box = list_box items: (1..12).to_a, width:60, choose: current_date.month.to_i
      @end_year_box = list_box items: (2013..current_date.year.to_i).to_a, width:100, choose: current_date.year.to_i
    end

    # TODO: Implement progress bar.
    #@p = progress width: 1.0
    
    # TODO: Use change handler for start date and end date to enable this button once we have valid dates?
    @report_button = button "Generate Report", width:1.0
    
    @report_button.click do
      if !Date.valid_date?(@start_year_box.text.to_i, @start_month_box.text.to_i, @start_day_box.text.to_i)
        # FIXME: Don't raise so many alerts. :(
        alert("Start date is not a valid date.")
        return
      end
      if !Date.valid_date?(@end_year_box.text.to_i, @end_month_box.text.to_i, @end_day_box.text.to_i)
        # FIXME: Don't raise so many alerts. :(
        alert("End date is not a valid date.")
        return
      end

      # FIXME: We do this conversion in a few places. Do it once, and pass the dates around as needed instead.
      start_date = Date.new(@start_year_box.text.to_i, @start_month_box.text.to_i, @start_day_box.text.to_i)
      end_date = Date.new(@end_year_box.text.to_i, @end_month_box.text.to_i, @end_day_box.text.to_i)

      # If our end date is before our start date, that makes no sense. Halt.
      if end_date < start_date
        # FIXME: Don't raise so many alerts. :(
        alert("End date cannot be before start date.")
        return
      end
      # FIXME: Don't raise so many alerts. :(
      alert("Generating Report")
      run_report(start_date.to_s, end_date.to_s)
      # FIXME: Don't raise so many alerts. :(
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

# Date inputs expected as string representations of dates
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