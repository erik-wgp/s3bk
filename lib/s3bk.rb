
require "rubygems"
require 'yaml'
require 'awesome_print'
require 'aws-sdk'
require 'date'
require 'active_support'
require 'active_support/time'
require "securerandom"

class S3bkUploader

   def initialize(config_file = nil)
      config_file ||= ENV["S3BK_CONFIG"]
      config_file ||= File.dirname(__FILE__) + "/../etc/s3bk.yml"
      if ! File.exists? config_file 
         raise ArgumentError, "Unable to locate config file"
      end
      @config = load_config(config_file)
   end

   def load_config(config)
      YAML.load(File.read(config)).to_h
   end

   def aws_s3
      @aws_s3 if @aws_s3

      cred = Aws::SharedCredentials.new(profile_name: @config["aws_profile"])
      Aws.config[:credentials] = cred
      @aws_s3 = Aws::S3::Resource.new(region: @config["aws_region"])
   end

   def generate_bucket_path(backup_type)
       @config["bk_map"][backup_type]["bucket_path"]
   end
   
   def generate_full_path(filename, backup_type)
      generate_bucket_path(backup_type) + "/" + File.basename(filename)
   end

   ### appending a uuid would make it difficult for an attacker to overwrite the backups
   ### if they have access to the upload credentials
   ### (the upload credentials should not be able to list the bucket)   
   def generate_full_path_secure(filename, backup_type)
      generate_bucket_path(backup_type) + "/" + File.basename(filename) + "-" + SecureRandom.uuid
   end
   
   def upload_file(filename, backup_type)
   
      if ! File.exists? filename
         STDERR.print "filename doesn't exist, upload failed\n"
         return false
      end
   
      backup_config = @config["bk_map"][backup_type]
   
      obj = aws_s3.bucket(backup_config["bucket_name"]).object(generate_full_path_secure(filename, backup_type))
   
      if obj.upload_file(filename, storage_class: backup_config["storage"])
         puts "uploaded #{filename} as #{backup_type}"
         return true
      else
         STDERR.print "failed to upload #{filename}"
         return false
      end
   end
   
   def determine_backup_type_from_filename(filename)
      file_base = File.basename(filename)
   
      datestring = parse_datestring_basic(file_base)
   
      @config["bk_map"].select { |bktype, bktype_info|
         next unless bktype_info["interval"]      
         datestring_matches_interval(datestring, bktype_info["interval"])
      }.sort_by { |k,v| v["retention"] }.reverse.first.first
   end
   
   def datestring_matches_interval(datestring, interval_desc)
      if interval_desc == "daily"
         return true
      elsif interval_desc == "evendays"
         return datestring.to_i.even?
      elsif interval_desc == "odddays"
         return datestring.to_i.odd?
      elsif interval_desc == "weekly"
         return Date.parse(datestring).wday == 6
      elsif interval_desc == "monthly"
         return Date.parse(datestring).mday == 1
      elsif interval_desc == "yearly"
         return Date.parse(datestring).yday == 1
      else
         return false
      end
   end
   
   # y2.1k bug
   def parse_datestring_basic(filename)
      file_base = File.basename(filename)
      /(?<datestring>20\d{6})/ =~ file_base
      return datestring
   end
   
   ### generate some whitespace based on backup retention
   ### for visualization purposes (not to scale)
   def tabs_for(backup_type)
      @tab_map ||= generate_tab_map
      return @tab_map[backup_type]
   end
   
   def generate_tab_map
      tab_map = {}
   
      sorted_bktypes = @config["bk_map"].sort { |a,b| a[1]["retention"] <=> b[1]["retention"] }
   
      i = 0
      sorted_bktypes.each do |bktype|
         tab_map[bktype[0]] = " " * i
         i += 8
      end
   
      tab_map
   end
end
