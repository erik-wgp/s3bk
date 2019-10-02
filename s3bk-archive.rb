#!/bin/env ruby

require File.dirname(__FILE__) + '/s3bk.rb'
include S3bk

ARGV.each do |srcfile|
   S3bk::s3bk_upload_file(srcfile, "archive")
end
