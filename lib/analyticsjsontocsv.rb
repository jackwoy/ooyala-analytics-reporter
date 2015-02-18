require 'rubygems'
require 'json'
require 'csv'

class AnalyticsJSONtoCSV
	def csvFromFile(inFile, outFile, number_days)
		csvHeaders = ["Video Title","Plays","Avg. Unique Users / Day","Avg. Videos / User / Day","Video Conversion Rate","Hours Delivered","Avg. Time Watched / Video"]

		# Crunch numbers for derived statistics
		file = File.read(inFile)
		data_hash = JSON.parse(file)

		crunchedArray = Array.new

		data_hash['results'].each do |result|
			name = result["name"]
			video_hash = result.fetch("metrics",{}).fetch("video",{})
			plays = video_hash.fetch("plays",0)
			displays = video_hash.fetch("displays",0)
			uniq_plays_daily_uniqs = video_hash.fetch("uniq_plays",{}).fetch("daily_uniqs",0)
			time_watched_microseconds = video_hash.fetch("time_watched",0)

			avg_unique_user_per_day = uniq_plays_daily_uniqs.to_f/number_days.to_f
			avg_vid_per_user_per_day = (plays != 0 && avg_unique_user_per_day != 0) ? (plays.to_f/number_days.to_f)/avg_unique_user_per_day.to_f : 0
			video_conversion_rate = (plays != 0 && displays != 0) ? (plays.to_f/displays.to_f)*100 : 0
			hours_delivered = time_watched_microseconds/1000.0/60.0/60.0
			# avg_time_watched_per_video is expressed as hh:mm:ss in output from Backlot, so easiest to convert to seconds and format the result.
			avg_time_watched_per_video_seconds = plays > 0 ? time_watched_microseconds/1000/plays : 0
			avg_time_watched_per_video_formatted = Time.at(avg_time_watched_per_video_seconds).utc.strftime("%H:%M:%S")
			crunchedArray.push([name,plays,avg_unique_user_per_day.round(2),avg_vid_per_user_per_day.round(2),video_conversion_rate.round(2),hours_delivered.round(2),avg_time_watched_per_video_formatted])
		end

		# Sort array
		sortedArray = crunchedArray.sort_by{|k|k[1]}.reverse

		# Output numbers into CSV
		CSV.open(outFile, "wb") do |csv|
			csv << csvHeaders
			sortedArray.each do |line|
				csv << line
			end
		end
	end
end