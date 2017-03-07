#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'aws-sdk'
require 'terminal-table'
require 'yaml'

config = YAML.load_file('config.yml')

def check_ec2(config, reservations, instances)
  config['regions'].each do |region|
    connection = Aws::EC2::Client.new(
      credentials: Aws::Credentials.new(config['access_key_id'], config['secret_access_key']),
      region: region)

    connection.describe_reserved_instances(filters: [{:name => "state", :values => ['active']}]).reserved_instances.each do |ri|
      type = 'ec2:' + ri.instance_type
      type += ':vpc' if ri.product_description =~ /VPC/
      type += ':' + (ri.availability_zone || 'none')
      if ri.product_description =~ /VPC/
        type = 'ec2:' + ri.instance_type + ':vpc'
      else
        type = 'ec2:' + ri.instance_type + ':' + (ri.availability_zone || 'none')
      end
      reservations[type] += ri.instance_count
    end

    connection.describe_instances(filters: [{:name => "instance-state-name", :values => ['running']}]).reservations.each do |r|
      r.instances.each do |i|
        if i.vpc_id.nil?
          type = 'ec2:' + i.instance_type + ':' + i.placement.availability_zone
        else
          type = 'ec2:' + i.instance_type + ':vpc'
        end
        instances[type] += 1
      end
    end
  end
end

def check_elasticache(config, reservations, instances)
  config['regions'].each do |region|
    connection = Aws::ElastiCache::Client.new(
      credentials: Aws::Credentials.new(config['access_key_id'], config['secret_access_key']),
      region: region)

    connection.describe_reserved_cache_nodes.reserved_cache_nodes.each do |r|
      next unless r[:state] == 'active'
      type = 'elasticache:' + r[:product_description] + ':' + r[:cache_node_type]
      type << ':' << region
      reservations[type] += 1
    end

    connection.describe_cache_clusters.cache_clusters.each do |c|
      next unless c[:cache_cluster_status] == 'available'
      type = 'elasticache:' + c[:engine] + ':' + c[:cache_node_type]
      type += ':' + region
      instances[type] += c[:num_cache_nodes]
    end
  end
end

def check_rds(config, reservations, instances)
  config['regions'].each do |region|
    connection = Aws::RDS::Client.new(
      credentials: Aws::Credentials.new(config['access_key_id'], config['secret_access_key']),
      region: region)

    connection.describe_reserved_db_instances().reserved_db_instances.each do |i|
      next unless i[:state] == 'active'
      type = 'rds:' + i[:product_description] + ':' + i[:db_instance_class]
      type += '-multi_az' if i[:multi_az]
      type += ':' + region
      reservations[type.gsub('postgresql', 'postgres')] += i[:db_instance_count]
    end

    connection.describe_db_instances().db_instances.each do |i|
      type = 'rds:' + i[:engine] + ':' + i[:db_instance_class]
      type += '-multi_az' if i[:multi_az]
      type += ':' + region
      instances[type] += 1
    end
  end
end

def check_redshift(config, reservations, instances)
  config['regions'].each do |region|
    connection = Aws::Redshift::Client.new(
      credentials: Aws::Credentials.new(config['access_key_id'], config['secret_access_key']),
      region: region)

    connection.describe_reserved_nodes.reserved_nodes.each do |i|
      next unless i[:state] == 'active'
      type = 'redshift:' + i[:node_type]
      type += ':' + region
      reservations[type] += i[:node_count]
    end

    connection.describe_clusters.clusters.
      select { |i| i[:cluster_status] == 'available' }.each do |i|
      type = 'redshift:' + i[:node_type]
      type += ':' + region
      instances[type] += i[:number_of_nodes]
    end
  end
end

reservations = Hash.new(0)
instances = Hash.new(0)

check_ec2(config, reservations, instances) if config['products'].include? 'ec2'
check_elasticache(config, reservations, instances) if config['products'].include? 'elasticache'
check_rds(config, reservations, instances) if config['products'].include? 'rds'
check_redshift(config, reservations, instances) if config['products'].include? 'redshift'

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

types = instances.keys + reservations.keys
types.uniq.sort.each do |type|
  table.add_row [type,
                 unused_reservations[type],
                 unreserved_instances[type],
                 reservations[type],
                 instances[type]] 
end

puts table
