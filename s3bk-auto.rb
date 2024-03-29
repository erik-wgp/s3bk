#!/bin/env ruby

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require 's3bk.rb'
require 'optparse'

options = {}

opts = OptionParser.new do |opts|
   opts.banner = "Usage: s3bk-auto.rb [ --fake ] [ --rename-suffix <suffix> ] [ --move-to-dir <dir> ] file1 [ file2 [ ... ] ]"
   opts.on("--rename-suffix SUFFIX", "on upload success, rename file with appended SUFFIX") 
   opts.on("--move-to-dir DIR", "on success, move file to DIR (relative to src file[s])")
   opts.on("--backup-type TYPE", "override backup type rather than trying to parse date from filename")
   opts.on("--fake", "just print out what backup type would be used for the file")
end

opts.parse!(into: options)

if options[:"move-to-dir"]
   if ! Dir.exists?(options[:"move-to-dir"])
      STDERR.print options[:"move-to-dir"] + " doesn't exist, aborting\n"
      exit 1
   end
end

s3bk = S3bkUploader.new

ARGV.each do |srcfile|
   if ! File.exists? srcfile
      STDERR.print "#{srcfile} doesn't exist\n"
      next
   end

   destfile = srcfile

   ### first, make sure we'll be able to move/rename the file as needed
   if options[:"move-to-dir"]
      destfile = File.dirname(destfile) + "/" + options[:"move-to-dir"] + "/" + File.basename(srcfile)
   end

   if options[:"rename-suffix"]
      destfile = destfile + options[:"rename-suffix"]
   end

   if srcfile != destfile
      if File.exists?(destfile)
         STDERR.print "skipping #{srcfile}: #{destfile} already exists\n"
         next
      end
   else
      destfile = nil
   end

   backup_type = options[:"backup-type"]
   backup_type ||= s3bk.determine_backup_type_from_filename(srcfile)

   if options[:fake]
      puts "(fake) #{srcfile} -> #{backup_type}"
      if destfile
         puts "\twould rename to #{destfile}"
      end
   elsif s3bk.upload_file(srcfile, backup_type)
      if destfile
         puts "\trename: #{srcfile} #{destfile}"
         File.rename(srcfile, destfile)
      end
   else
      # error printed in library
   end
end
