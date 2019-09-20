#!/bin/env ruby

require File.dirname(__FILE__) + '/s3bk.rb'

ARGV.each do |srcfile|
   s3bk_upload_file(srcfile, "archive")
end
