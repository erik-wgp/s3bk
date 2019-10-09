#!/bin/env ruby

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require 's3bk.rb'

s3bk = S3bkUploader.new

( -32..32 ).each do |n|
   backup_type = s3bk.determine_backup_type_from_filename("file_" + (Time.now + n.day).strftime("%Y%m%d"))
   printf("%-12s %s %-20s\n", (Time.now + n.day).strftime("%Y-%m-%d"), s3bk.tabs_for(backup_type), backup_type)
   n += 1
end

