# ooyala-analytics-reporter
Ruby scripts for producing CSV exports from Ooyala Backlot that are not restricted to 500 lines

This version is likely to be a little rough around the edges, but easier to use than previous versions.

**How to Use**

1. Open config.yaml in a text editor
2. Replace API_KEY_HERE and API_SECRET_HERE with your API Key and API Secret from Backlot
3. Open a terminal window
4. Run generate-report.rb -s START_DATE -e END_DATE (replacing START_DATE and END_DATE with your desired dates in ISO format, e.g. generate-report.rb -s 2015-01-26 -e 2015-02-01 for January 26th 2015 to February 1st 2015.)
5. The output folder should now contain a file with a name starting with csv_analytics_results.