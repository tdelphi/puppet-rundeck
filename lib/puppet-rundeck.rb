#
# Copyright 2010, James Turnbull
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
require 'puppet'
require 'puppet/rails'
require 'builder/xchar'

class PuppetRundeck < Sinatra::Base

  include Puppet

  class << self
    attr_accessor :config_file
    attr_accessor :username

    def configure
      Puppet[:config] = PuppetRundeck.config_file
      Puppet.parse_config
      Puppet::Rails.connect
    end
  end

  def xml_escape(input)
    # don't know if is string, so convert to string first, then to XML escaped text.
    return input.to_s.to_xs
  end

  get '/' do
    response = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd"><project>'
    Host = Puppet::Rails::Host
    Host.all.each do |h|
      puts "Processing #{h.name}"
      facts = h.get_facts_hash
      response << <<-EOH
<node name="#{xml_escape(h.name)}"
      type="Node"
      description="#{xml_escape(h.name)}"
      osArch="#{xml_escape(facts["kernel"].first.value)}"
      osFamily="#{xml_escape(facts["kernel"].first.value)}"
      osName="#{xml_escape(facts["operatingsystem"].first.value)}"
      osVersion="#{xml_escape(facts["operatingsystemrelease"].first.value)}"
      tags="nil"
      username="#{xml_escape(PuppetRundeck.username)}"
      hostname="#{xml_escape(facts["fqdn"].first.value)}"/>
EOH
    end
    response << "</project>"
    response
  end
end