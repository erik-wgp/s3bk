$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "rubygems"
require 'yaml'
require 'awesome_print'
require 'aws-sdk'
require 'date'
require 'active_support'
require 'active_support/time'
require "securerandom"

def load_config
   config = ENV["S3BK_CONFIG"]
   config ||= File.dirname(__FILE__) + "/s3bk.yml"
   return YAML.load(File.read(config)).to_h
end

def s3bk_generate_bucket_path(backup_type)
#   $s3bk_config["bk_map"][backup_type]["bucket_name"] + "/" + $s3bk_config["bk_map"][backup_type]["bucket_path"]
    $s3bk_config["bk_map"][backup_type]["bucket_path"]
end

def s3bk_generate_full_path(filename, backup_type)
   s3bk_generate_bucket_path(backup_type) + "/" + File.basename(filename)
end

def s3bk_generate_full_path_secure(filename, backup_type)
   s3bk_generate_bucket_path(backup_type) + "/" + File.basename(filename) + "-" + SecureRandom.uuid
end

def s3bk_upload_file(filename, backup_type)
   $s3bk_aws ||= Aws::S3::Resource.new(region: $s3bk_config["aws_region"])

   if ! File.exists? filename
      STDERR.print "filename doesn't exist, upload failed\n"
      return false
   end

   backup_config = $s3bk_config["bk_map"][backup_type]

   obj = $global_s3.bucket(backup_config["bucket_name"]).object(s3bk_generate_full_path_secure(filename, backup_type))

   if obj.upload_file(filename, storage_class: backup_config["storage"])
#   resp = $global_s3.put_object( {
#      body: filename,
#      bucket: backup_config["bucket_name"],
#      key: s3bk_generate_full_path_secure(filename, backup_type),
#      storage_class: backup_config["storage"]
#   })
#   ap resp
#   if resp
      puts "uploaded #{filename} as #{backup_type}"
      return true
   else
      STDERR.print "failed to upload #{filename}"
      return false
   end
end

def s3bk_determine_backup_type_from_filename(filename)
   file_base = File.basename(filename)

   datestring = s3bk_parse_datestring_basic(file_base)

   $s3bk_config["bk_map"].select { |bktype, bktype_info|
      next unless bktype_info["interval"]      
      s3bk_datestring_matches_interval(datestring, bktype_info["interval"])
   }.sort_by { |k,v| v["retention"] }.reverse.first.first
end

def s3bk_datestring_matches_interval(datestring, interval_desc)
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

def s3bk_parse_datestring_basic(filename)
   file_base = File.basename(filename)
   /(?<datestring>\d{8})/ =~ file_base
   return datestring
end

### generate some whitespace based on backup retention
### for visualization purposes
def s3bk_tabs_for(backup_type)
   $s3bk_tab_map ||= s3bk_get_tab_map
   return $s3bk_tab_map[backup_type]
end

def s3bk_get_tab_map
   tab_map = {}

   sorted_bktypes = $s3bk_config["bk_map"].sort { |a,b| a[1]["retention"] <=> b[1]["retention"] }

   i = 0
   sorted_bktypes.each do |bktype|
      tab_map[bktype[0]] = " " * i
      i += 8
   end

   tab_map
end

$s3bk_config = load_config
cred = Aws::SharedCredentials.new(profile_name: $s3bk_config["aws_profile"])
Aws.config[:credentials] = cred
$global_s3 ||= Aws::S3::Resource.new

