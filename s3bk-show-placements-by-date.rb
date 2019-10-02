#!/bin/env ruby

require File.dirname(__FILE__) + '/s3bk.rb'
include S3bk

( -32..32 ).each do |n|
   backup_type = s3bk_determine_backup_type_from_filename("file_" + (Time.now + n.day).strftime("%Y%m%d"))
   printf("%-12s %s %-20s\n", (Time.now + n.day).strftime("%Y-%m-%d"), S3bk::s3bk_tabs_for(backup_type), backup_type)
   n += 1
end

