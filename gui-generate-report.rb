Shoes.setup do
  gem 'rest-client'
end
require 'date'
require './lib/reportgenerator'

Shoes.app title: "Ooyala Analytics Report Generator", width: 400, height: 260, resizable: false do
  current_date = DateTime.now
  @root_stack = stack margin:0.05 do
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
    @error_status = para "", stroke:red
    @generation_status = para ""
    # TODO: Implement progress bar.
    #@p = progress width: 1.0
    
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
      reporter = ReportGenerator.new
      reporter.runReport(start_date.to_s, end_date.to_s)
      @generation_status.text = "Done! CSV saved to output folder."
    end
    # Sample progress bar animation code
    # TODO: Implement progress bar.
    #animate do |i|
    #   @p.fraction = (i % 100) / 100.0
    #end
  end
end