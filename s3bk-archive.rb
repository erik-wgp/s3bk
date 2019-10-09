#!/bin/env ruby

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require '/s3bk.rb'

s3bk = S3bkUploader.new

ARGV.each do |srcfile|
   s3bk.upload_file(srcfile, "archive")
end
