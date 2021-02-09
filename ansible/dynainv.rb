#!/usr/bin/env ruby


#l=STDIN.read

require 'yaml'

out = {"_meta" => {"hostvars" => {}}}

#if ARGV.include? '--list'
  instlist = `yc compute instance list --format yaml`
  h = YAML.load(instlist)
#end

h.map{|e| [e['name'], e['network_interfaces'][0]['primary_v4_address']['one_to_one_nat']['address']]}
  .each{|name, ip|
    if name.match?(/^reddit-(db|app)$/)
      name_short = name.sub(/^reddit-/, '')
      out[name_short] = { hosts: [ ip ] }
      out['all'] ||= []; out['all'] << ip
    end
  }

require 'json'

STDOUT.puts out.to_json
