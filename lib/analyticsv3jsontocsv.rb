require 'rubygems'
require 'json'
require 'csv'

class AnalyticsV3JSONtoCSV
	def csvFromFile(inFile, outFile, number_days)
		csvHeaders = ["Name","Displays","Plays Requested","Video Starts","Play Conversion Rate","Video Conversion Rate"," Hours Watched","Avg. Time Watched per Video","Unique Users","Avg. Plays Requested per User","Playthrough 25%","Playthrough 50%","Playthrough 75%","Playthrough 100%","Embed Code"]

		# Crunch numbers for derived statistics
		file = File.read(inFile)
		data_hash = JSON.parse(file)

		crunchedArray = Array.new
		# results 1 > result 0:n > data 0:1 > datum 0:n > group | metrics
		data_hash['results'].each do |result|
			result['data'].each do |datum|
				video_hash = datum.fetch("metrics",{})
				name = datum.fetch("group").fetch("name")
				displays = video_hash.fetch("displays",0)
				plays_requested = video_hash.fetch("plays_requested",0)
				video_starts = video_hash.fetch("video_starts",0)
				play_conversion_rate = (plays_requested != 0 && displays != 0) ? (plays_requested.to_f/displays.to_f)*100 : 0
				video_conversion_rate = (plays_requested != 0 && video_starts != 0) ? (video_starts.to_f/plays_requested.to_f)*100 : 0
				time_watched_milliseconds = video_hash.fetch("time_watched",0)
				hours_watched = time_watched_milliseconds.to_f/1000.0/60.0/60.0
				# avg_time_watched_per_video is expressed as hh:mm:ss in output from Backlot, so easiest to convert to seconds and format the result.
				avg_time_watched_per_video_seconds = video_starts > 0 ? time_watched_milliseconds/1000/video_starts : 0
				avg_time_watched_per_video_formatted = Time.at(avg_time_watched_per_video_seconds).utc.strftime("%H:%M:%S")
				unique_users = video_hash.fetch("uniq_plays_requested",0)
				avg_plays_requested_per_user = (plays_requested != 0 && unique_users != 0) ? (plays_requested.to_f/unique_users.to_f).round(2) : 0
				pt25 = video_hash.fetch("playthrough_25",0)
				pt50 = video_hash.fetch("playthrough_50",0)
				pt75 = video_hash.fetch("playthrough_75",0)
				pt100 = video_hash.fetch("playthrough_100",0)
				embedCode = datum.fetch("group").fetch("asset")
				crunchedArray.push([name,displays,plays_requested,video_starts,play_conversion_rate.to_s,video_conversion_rate,hours_watched,avg_time_watched_per_video_formatted,unique_users,avg_plays_requested_per_user,pt25,pt50,pt75,pt100,embedCode])
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