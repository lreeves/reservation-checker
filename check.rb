#!/usr/bin/env ruby

require 'aws-sdk'
require 'json'
require 'terminal-table'
require 'yaml'

config = YAML.load_file('config.yml')

region = 'us-east-1'

AWS.config(
  access_key_id: config['access_key_id'],
  secret_access_key: config['secret_access_key'],
  region: region)

reservations = Hash.new(0)
instances = Hash.new(0)

ec2 = AWS::EC2.new
ec2.reserved_instances.select { |x| x.state == 'active' }.each do |ri|
  type = 'ec2:' + ri.instance_type + ':' + ri.availability_zone
  reservations[type] += ri.instance_count
end

unused_reservations = reservations.clone

ec2.instances.select { |x| x.status == :running }.each do |i|
  type = 'ec2:' + i.instance_type + ':' + i.availability_zone
  unused_reservations[type] -= 1 unless unused_reservations[type] <= 0
  instances[type] += 1
end

unreserved_instances = instances.clone

reservations.each do |type, count|
  unreserved_instances[type] -= count
  unreserved_instances[type] = 0 if unreserved_instances[type] < 0
end

table = Terminal::Table.new(headings: ['Type', 'Unused Reservations',
                                       'Unreserved Units',
                                       'Total Reservations', 'Total Units'])
instances.keys.sort.each do |type|
  table.add_row [type,
                 unused_reservations[type],
                 unreserved_instances[type],
                 reservations[type],
                 instances[type]]
end

puts table
