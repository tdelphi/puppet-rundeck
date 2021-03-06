#
# Copyright 2012, James Turnbull
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'sinatra/base'
require 'builder/xchar'

begin
  require 'puppet'
rescue LoadError
  puts "You need to have Puppet 0.25.5 or later installed"
end

class PuppetRundeck < Sinatra::Base

  class << self
    attr_accessor :config_file
    attr_accessor :username
    attr_accessor :source
    attr_accessor :ssh_port

    def configure
      Puppet[:config] = PuppetRundeck.config_file
      Puppet.parse_config
    end
  end

  def xml_escape(input)
    # don't know if is string, so convert to string first, then to XML escaped text.
    return input.to_s.to_xs
  end

  def respond(required_tag=nil,required_facts=nil,uname=nil,use_tags=nil,add_facts=nil)
    response['Content-Type'] = 'text/xml'
    response_xml = %Q(<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd">\n<project>\n)

      if use_tags.nil?
        use_tags = '1'
      end
      should_use_tags = (! required_tag.nil?) || (use_tags == '1')

      # Fix for 2.6 to 2.7 indirection difference
      Puppet[:clientyamldir] = Puppet[:yamldir]
      if Puppet::Node.respond_to? :terminus_class
        Puppet::Node.terminus_class = :yaml
        nodes = Puppet::Node.search("*")
      else
        Puppet::Node.indirection.terminus_class = :yaml
        nodes = Puppet::Node.indirection.search("*")
      end

      if ! required_facts.nil?
        # this should convert string 'fact1=fact1_value&fact2=fact2_value' to array [fact1, fact1_value, fact2, fact2_value]
        local_required_facts = Hash[*required_facts.split(/[=&]/)].to_a
      else
        local_required_facts = nil
      end

      nodes.each do |n|
        if should_use_tags
          if Puppet::Node::Facts.respond_to? :find
            tags = Puppet::Resource::Catalog.find(n.name).tags
          else
            tags = Puppet::Resource::Catalog.indirection.find(n.name).tags
          end
        else
          tags = nil
        end

        if ! required_tag.nil?
          next if ! tags.include? required_tag
        end

        facts = n.parameters

        if ! local_required_facts.nil?
          next if ! (local_required_facts-facts.to_a).empty?
        end

        os_family = facts["kernel"] =~ /windows/i ? 'windows' : 'unix'

        facts_string = nil

        if !add_facts.nil?
          add_facts.split(/,|;| +/).each { |fact_name|
            fact = facts[fact_name]
            if (!fact.nil?) and (!fact.empty?)
              if facts_string.nil?
                facts_string = fact
              else
                facts_string = [facts_string, fact].join(',')
              end
            end
          }
        end

        if uname == nil
          targetusername = PuppetRundeck.username
        else
          targetusername = uname
        end

        if tags.nil?
          tags_string = n.environment
        else
          tags_string = [n.environment, tags.join(',')].join(',')
        end
        
        if !facts_string.nil?
          tags_string = [tags_string,facts_string].join(',')
        end

        hostname = "#{facts["ipaddress"]}"
        if PuppetRundeck.ssh_port.to_s != '22' then
          hostname = "#{hostname}" ":" "#{PuppetRundeck.ssh_port.to_s}"
        end

      response_xml << <<-EOH
<node name="#{xml_escape(n.name)}"
      type="Node"
      description="#{xml_escape(n.name)}"
      osArch="#{xml_escape(facts["kernel"])}"
      osFamily="#{xml_escape(os_family)}"
      osName="#{xml_escape(facts["operatingsystem"])}"
      osVersion="#{xml_escape(facts["operatingsystemrelease"])}"
      tags="#{xml_escape(tags_string)}"
      username="#{xml_escape(targetusername)}"
      hostname="#{xml_escape(hostname)}/>
EOH
    end
    response_xml << "</project>"
    response_xml
  end

  require 'pp'

  get '/tag/:tag' do
    respond(params[:tag], nil, params["user"], params["use_tags"], params["add_facts"])
  end

  get '/facts/:fact' do
    respond(nil, params[:fact], params["user"], params["use_tags"], params["add_facts"])
  end

  get '/' do
    respond(nil, nil, params["user"], params["use_tags"], params["add_facts"])
  end

end
