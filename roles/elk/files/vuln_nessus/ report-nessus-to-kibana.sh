rm -f /nessusreports/*
ruby /nessus6-report-downloader.rb
python /VulntoES.py -i /nessusreports/Report_* -I vulns -e https://localhost:9200 -r nessus
