#!/usr/bin/env ruby
#################################################################################################
# Name: Nessus 6 Report Downloader
# Author: Travis Lee
#
# Version: 1.0
# Last Updated: 2/28/2016
#
# Description:  Interactive script that connects to a specified Nessus 6 server using the
#		Nessus REST API to automate mass report downloads. It has the ability to download
#		multiple or all reports/file types/chapters and save them to a folder of
#		your choosing. This has been tested with Nessus 6.5.5 and *should* work with
#		Nessus 6+, YMMV.
#
#		File types include: NESSUS, HTML, PDF, CSV, and DB. 
#
#		Chapter types include: Vulnerabilities By Plugin, Vulnerabilities By Host, 
#		Hosts Summary (Executive), Suggested Remediations, Compliance Check (Executive), 
#		and Compliance Check.
#
# Usage: ruby ./nessus6-report-downloader.rb
#
# Reference: https://<nessus-server>:8834/api
#
#################################################################################################

require 'net/http'
require 'fileutils'
require 'io/console'
require 'date'
require 'json'
require 'openssl'

# This method will download the specified file type from specified reports
def report_download(http, headers, reports, reports_to_dl, filetypes_to_dl, chapters_to_dl, rpath, db_export_pw)
	begin
		puts "\nDownloading report(s). Please wait..."

		# if all reports are selected
		if reports_to_dl[0].eql?("all")
			reports_to_dl.clear
			# re-init array with all the scan ids
			reports["scans"].each do |scan|
				reports_to_dl.push(scan["id"].to_s)
			end	
		end
		
		# iterate through all the indexes and download the reports
		reports_to_dl.each do |rep|
			rep = rep.strip
			filetypes_to_dl.each do |ft|
			
				# export report
				puts "\n[+] Exporting scan report, scan id: " + rep + ", type: " + ft
				path = "/scans/" + rep + "/export"
				data = {'format' => ft, 'chapters' => chapters_to_dl, 'password' => db_export_pw}
				resp = http.post(path, data.to_json, headers)
				fileid = JSON.parse(resp.body)
			
				# check export status
				status_path = "/scans/" + rep + "/export/" + fileid["file"].to_s + "/status"
				loop do
					sleep(5)
					puts "[+] Checking export status..."
					status_resp = http.get(status_path, headers)
					status_result = JSON.parse(status_resp.body)
					break if status_result["status"] == "ready"
					puts "[-] Export not ready yet, checking again in 5 secs."
				end

				# download report
				puts "[+] Report ready for download..."
				dl_path = "/scans/" + rep + "/export/" + fileid["file"].to_s + "/download"
				dl_resp = http.get(dl_path, headers)

				# create final path/filename and write to file
				fname_temp = dl_resp.response["Content-Disposition"].split('"')
				fname = "#{rpath}/#{fname_temp[1]}"
					
				# write file
				open(fname, 'w') { |f|
  					f.puts dl_resp.body
  				}
  			
  				puts "[+] Downloading report to: #{fname}"
  			end
		end
		
	rescue StandardError => download_report_error
		puts "\n\nError downloading report: #{download_report_error}\n\n"
		exit
	end
end

# This method will return a list of all the reports on the server
def get_report_list(http, headers)
	begin
		# Try and do stuff
		path = "/scans"
		resp = http.get(path, headers)

		#puts "Number of reports found: #{reports.count}\n\n"

		results = JSON.parse(resp.body)

		printf("%-7s %-50s %-30s %-15s\n", "Scan ID", "Name", "Last Modified", "Status")
		printf("%-7s %-50s %-30s %-15s\n", "-------", "----", "-------------", "------")

		# print out all the reports
		results["scans"].each do |scan|
			printf("%-7s %-50s %-30s %-15s\n", scan["id"], scan["name"], DateTime.strptime(scan["last_modification_date"].to_s,'%s').strftime('%b %e, %Y %H:%M %Z'), scan["status"])
		end
		return results
		
	rescue StandardError => get_scanlist_error
		puts "\n\nError getting scan list: #{get_scanlist_error}\n\n"
		exit
	end
end


# This method will make the initial login request and set the token value to use for subsequent requests
def get_token(http, username, password)
	begin
		path = "/session"
		data = {'username' => username, 'password' => password}
		resp = http.post(path, data.to_json, 'Content-Type' => 'application/json')

		token = JSON.parse(resp.body)
		headers = { 
			"User-Agent" => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:25.0) Gecko/20100101 Firefox/25.0',
			"X-Cookie" => 'token=' + token["token"],
			"Accept" => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
			"Accept-Language" => 'en-us,en;q=0.5',
			"Accept-Encoding" => 'text/html;charset=UTF-8',
			"Cache-Control" => 'max-age=0',
			"Content-Type" => 'application/json'
		 }
		return headers
		
	rescue StandardError => get_token_error
		puts "\n\nError logging in/getting token: #{get_token_error}\n\n"
		exit
	end
end

### MAIN ###

puts "\nNessus 6 Report Downloader 1.0"

# Collect server info
#print "\nEnter the Nessus Server IP: "
#nserver = gets.chomp.to_s
nserver = "1.2.3.4"
#print "Enter the Nessus Server Port [8888]: "
#nserverport = gets.chomp.to_s
nserverport = "443"
if nserverport.eql?("")
	nserverport = "8888"
end

# https object
http = Net::HTTP.new(nserver, nserverport)	
http.use_ssl = true				
http.verify_mode = OpenSSL::SSL::VERIFY_NONE	

# Collect user/pass info
#print "Enter your Nessus Username: "
#username = gets.chomp.to_s
username = "user"

#print "Enter your Nessus Password (will not echo): "
#password = STDIN.noecho(&:gets).chomp.to_s

password = "pass"

# login and get token cookie
headers = get_token(http, username, password)

# get list of reports
puts "\n\nGetting report list..."
reports = get_report_list(http, headers)
#print "Enter the report(s) your want to download (comma separate list) or 'all': "
#reports_to_dl = (gets.chomp.to_s).split(",")
#reports_to_dl = "all"
reports_to_dl = ("111").split(",")
if reports_to_dl.count == 0
	puts "\nError! You need to choose at least one report!\n\n"
	exit
end

# select file types to download
puts "\nChoose File Type(s) to Download: "
puts "[0] Nessus (No chapter selection)"
puts "[1] HTML"
puts "[2] PDF"
puts "[3] CSV (No chapter selection)"
puts "[4] DB (No chapter selection)"
#print "Enter the file type(s) you want to download (comma separate list) or 'all': "
#filetypes_to_dl = (gets.chomp.to_s).split(",")
filetypes_to_dl = ("0").split(",")

if filetypes_to_dl.count == 0
	puts "\nError! You need to choose at least one file type!\n\n"
	exit
end

# see which file types to download
formats = []
cSelect = false
dbSelect = false
filetypes_to_dl.each do |ft|
	case ft.strip
	when "all"
	  formats.push("nessus")
	  formats.push("html")
	  formats.push("pdf")
	  formats.push("csv")
	  formats.push("db")
	  cSelect = true
	  dbSelect = true
	when "0"
	  formats.push("nessus")
	when "1"
	  formats.push("html")
  	  cSelect = true
	when "2"
	  formats.push("pdf")
	  cSelect = true
	when "3"
	  formats.push("csv")
	when "4"
	  formats.push("db")
	  dbSelect = true
	end
end

# enter password used to encrypt db exports (required)
db_export_pw = ""
if dbSelect
	print "\nEnter a Password to encrypt the DB export (will not echo): "
	db_export_pw = STDIN.noecho(&:gets).chomp.to_s
	print "\n"
end

# select chapters to include, only show if html or pdf is in file type selection
chapters = ""
if cSelect
	puts "\nChoose Chapter(s) to Include: "
	puts "[0] Vulnerabilities By Plugin"
	puts "[1] Vulnerabilities By Host"
	puts "[2] Hosts Summary (Executive)"
	puts "[3] Suggested Remediations"
	puts "[4] Compliance Check (Executive)"
	puts "[5] Compliance Check"
	print "Enter the chapter(s) you want to include (comma separate list) or 'all': "
	chapters_to_dl = (gets.chomp.to_s).split(",")

	if chapters_to_dl.count == 0
		puts "\nError! You need to choose at least one chapter!\n\n"
		exit
	end

	# see which chapters to download
	chapters_to_dl.each do |chap|
		case chap.strip
		when "all"
		  chapters << "vuln_hosts_summary;vuln_by_plugin;vuln_by_host;remediations;compliance_exec;compliance;"
		when "0"
		  chapters << "vuln_by_plugin;"
		when "1"
		  chapters << "vuln_by_host;"
		when "2"
		  chapters << "vuln_hosts_summary;"
		when "3"
		  chapters << "remediations;"
		when "4"
		  chapters << "compliance_exec;"
		when "5"
		  chapters << "compliance;"
		end
	end
end

# create report folder
#print "\nPath to save reports to (without trailing slash): "
#rpath = gets.chomp.to_s
rpath = "/nessusreports"
unless File.directory?(rpath)
	FileUtils.mkdir_p(rpath)
end

# run report download
if formats.count > 0
	report_download(http, headers, reports, reports_to_dl, formats, chapters, rpath, db_export_pw)
end

puts "\nReport Download Completed!\n\n"
