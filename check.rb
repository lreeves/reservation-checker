#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'aws-sdk'
require 'json'
require 'terminal-table'
require 'yaml'

config = YAML.load_file('config.yml')

def check_ec2(config, reservations, instances)
  config['regions'].each do |region|
    connection = AWS::EC2.new(
      access_key_id: config['access_key_id'],
      secret_access_key: config['secret_access_key'],
      region: region)

    connection.reserved_instances.select { |x| x.state == 'active' }.each do |ri|
      type = 'ec2:' + ri.instance_type + ':' + ri.availability_zone
      reservations[type] += ri.instance_count
    end

    connection.instances.select { |x| x.status == :running }.each do |i|
      type = 'ec2:' + i.instance_type + ':' + i.availability_zone
      instances[type] += 1
    end
  end
end

def check_rds(config, reservations, instances)
  config['regions'].each do |region|
    connection = AWS::RDS.new(
      access_key_id: config['access_key_id'],
      secret_access_key: config['secret_access_key'],
      region: region)

    connection.client.describe_reserved_db_instances.data[:reserved_db_instances].each do |i|
      type = 'rds:' + i[:product_description] + ':' + i[:db_instance_class]
      type += '-multi_az' if i[:multi_az]
      type += ':' + region
      reservations[type] += i[:db_instance_count]
    end

    connection.client.describe_db_instances.data[:db_instances].each do |i|
      type = 'rds:' + i[:engine] + ':' + i[:db_instance_class]
      type += '-multi_az' if i[:multi_az]
      type += ':' + region
      instances[type] += 1
    end
  end
end

reservations = Hash.new(0)
instances = Hash.new(0)

check_ec2(config, reservations, instances) if config['products'].include? 'ec2'
check_rds(config, reservations, instances) if config['products'].include? 'rds'

unused_reservations = reservations.clone
unreserved_instances = instances.clone

instances.each do |type, count|
  unused_reservations[type] -= count
  unused_reservations[type] = 0 if unused_reservations[type] < 0
end

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
