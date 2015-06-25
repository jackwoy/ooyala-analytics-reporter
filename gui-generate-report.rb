Shoes.setup do
  gem 'rest-client'
end
require 'date'
require './lib/appconfig'
require './lib/reportgenerator'

Shoes.app title: "Ooyala Analytics Report Generator", width: 600, height: 500, resizable: true do
  config = AppConfig.new
  loaded_config = "config.local.yaml"
  custom_output_filename = nil
  config_hash = config.getConfig(loaded_config)
  current_date = DateTime.now
  @root_stack = stack margin:0.05 do
    flow do
      stack width: 250 do
        para "Start Date"
        flow do
          # TODO: Date picker seems a good candidate to split out into its own class.
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
        para "Custom metrics"
        @custom_metrics = edit_line
      end
      stack width: 250 do
        para "Options"
        flow do
          @v2_analytics_check = check
          para "Use v2 analytics"
        end
        para "Configuration File"
        @config_status = para "Using config %{config_name}" % { config_name: config_hash["name"] }
        @config_button = button "Change Config", width:1.0
        para "Output Folder"
        @output_status = para "Using default output filename"
        @output_button = button "Change Output Filename", width:1.0
      end
    end
    @error_status = para "", stroke:red
    @generation_status = para ""
    
    # TODO: Use change handler for start date and end date to enable this button once we have valid dates?
    @report_button = button "Generate Report", width:1.0
    
    @report_button.click do
      # Clear generation status text, in case it has been previously set.
      @generation_status.text = ""

      if !Date.valid_date?(@start_year_box.text.to_i, @start_month_box.text.to_i, @start_day_box.text.to_i)
        @error_status.text = "Start date is not a valid date."
        return
      end
      if !Date.valid_date?(@end_year_box.text.to_i, @end_month_box.text.to_i, @end_day_box.text.to_i)
        @error_status.text = "End date is not a valid date."
        return
      end

      # FIXME: We do this conversion in a few places. Do it once, and pass the dates around as needed instead.
      start_date = Date.new(@start_year_box.text.to_i, @start_month_box.text.to_i, @start_day_box.text.to_i)
      end_date = Date.new(@end_year_box.text.to_i, @end_month_box.text.to_i, @end_day_box.text.to_i)

      # If our end date is before our start date, that makes no sense. Halt.
      if end_date < start_date
        @error_status.text = "End date cannot be before start date."
        return
      end

      # Assuming we're now through all the validation steps successfully, so clear any previous error.
      @error_status.text = ""
      @generation_status.text = "Generating Report, please wait."

      metrics_text = nil

      # FIXME: Improve this rubbish. Late, tired, and rushed. Not a good combo for coding.
      if @custom_metrics.text.strip.length > 0
        metrics_text = @custom_metrics.text.split(',')
      end

      reporter = ReportGenerator.new
      reporter.runReport(start_date.to_s, end_date.to_s, @v2_analytics_check.checked?, "", loaded_config, custom_output_filename, metrics_text)
      @generation_status.text = "Done! CSV saved to output folder."
    end

    @config_button.click do
      config_filename = ask_open_file
      if config.validateConfig(config_filename)
        loaded_config = config_filename
        config_hash = config.getConfig(loaded_config)
        @config_status.text = "Using config %{config_name}" % { config_name: config_hash["name"] }
      else
        alert("Invalid config file selected.")
      end
    end
    @output_button.click do
      custom_output_filename = ask_save_file
      @output_status.text = "Using output file %{config_output}" % { config_output: custom_output_filename }
    end
  end
end