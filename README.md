# ooyala-analytics-reporter
Ruby scripts for producing CSV exports from Ooyala Backlot that are not restricted to 500 lines

This version is a bit (well, a lot) roughly cobbled together.

**How to Use**

*Producing JSON Data*
1. Open pull-analytics-from-live.rb in your favourite text editor
2. Set API_KEY and SECRET to your Ooyala Backlot API key and Secret key.
3. Uh, startDate and endDate don't actually do anything, so don't touch those.
4. To set the date range you want to produce analytics reports for, change the dates set for the url variable on line 33. Note that your end date should be one day later than the actual end date you want.
5. Change "testfile.json" on line 37 to the filename you want to write your first set of JSON results to.
6. Change "testfile2.json" on line 47 to the filename you want to write your second set of JSON results to.
7. If your results span more than two pages, you'll need to tweak the code. Or wait for the enhancements I'm working on.
8. Finally, run the script. There aren't any arguments to worry about, yet.

*Parsing JSON Data to CSV*
1. Open json-parse.rb in your favourite text editor.
2. Change number_days to the number of days between your reporting dates. (N.B., the actual number, not that number plus one.)
3. Change testfile.json on line 12 to the name of the file you want to read in.
4. Change calculatedOutput.csv on line 36 to the name of the file you want to write out to.
5. Run the script. No arguments, again.
6. Repeat steps 3, 4, and 5 until you've parsed all the JSON files you want to. Note that if you don't change the CSV output filename each time, it will be overwritten. 