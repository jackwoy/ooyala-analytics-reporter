require 'rubygems'
require 'json'
require 'csv'

class AnalyticsV3JSONtoCSV
	def csvFromFile(inFile, outFile, number_days)
		csvHeaders = ["Name","Displays","Plays Requested","Video Starts","Play Conversion Rate","Video Conversion Rate"," Hours Watched","Avg. Time Watched per Video","Unique Users","Avg. Plays Requested per User","Playthrough 25%","Playthrough 50%","Playthrough 75%","Playthrough 100%"]

		# Crunch numbers for derived statistics
		file = File.read(inFile)
		data_hash = JSON.parse(file)

		crunchedArray = Array.new
		# results 1 > result 0:n > data 0:1 > datum 0:n > group | metrics
		data_hash['results'].each do |result|
			result['data'].each do |datum|
				name = datum.fetch("group").fetch("name")
				
				
				#name = result["name"]
				#video_hash = result.fetch("metrics",{}).fetch("video",{})
				#displays = video_hash.fetch("displays",0)
				#plays_requested = video_hash.fetch("plays_requested",0)
				#video_starts = video_hash.fetch("video_starts",0)
				#uniq_plays_daily_uniqs = video_hash.fetch("uniq_plays",{}).fetch("daily_uniqs",0)
				#time_watched_microseconds = video_hash.fetch("time_watched",0)

				#avg_unique_user_per_day = uniq_plays_daily_uniqs.to_f/number_days.to_f
				#avg_vid_per_user_per_day = (plays != 0 && avg_unique_user_per_day != 0) ? (plays.to_f/number_days.to_f)/avg_unique_user_per_day.to_f : 0
				#video_conversion_rate = (plays != 0 && displays != 0) ? (plays.to_f/displays.to_f)*100 : 0
				#hours_delivered = time_watched_microseconds/1000.0/60.0/60.0
				# avg_time_watched_per_video is expressed as hh:mm:ss in output from Backlot, so easiest to convert to seconds and format the result.
				#avg_time_watched_per_video_seconds = plays > 0 ? time_watched_microseconds/1000/plays : 0
				#avg_time_watched_per_video_formatted = Time.at(avg_time_watched_per_video_seconds).utc.strftime("%H:%M:%S")
				#crunchedArray.push([name,plays,avg_unique_user_per_day.round(2),avg_vid_per_user_per_day.round(2),video_conversion_rate.round(2),hours_delivered.round(2),avg_time_watched_per_video_formatted])
				crunchedArray.push([name])
			end
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