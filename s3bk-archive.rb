#!/bin/env ruby

require File.dirname(__FILE__) + '/s3bk.rb'
s3bk = S3bkUploader.new

ARGV.each do |srcfile|
   s3bk.upload_file(srcfile, "archive")
end
