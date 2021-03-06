# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
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

require 'yaml'
require 'json'
require 'cyclid/constants'

module Cyclid
  module Cli
    # 'job' sub-command
    class Job < Thor
      desc 'submit FILENAME', 'Submit a job to be run'
      long_desc <<-LONGDESC
        Submit a job to be run by the server. FILENAME should be the path to a valid Cyclid job
        file, in either YAML or JSON format.

        Cyclid will attempt to detect the format of the job file automatically. You can force the
        parsing format using either the --yaml or --json options.

        The --yaml option causes the job file to be parsed as YAML.

        The --json option causes the job file to be parsed as JSON.
      LONGDESC
      option :yaml, aliases: '-y'
      option :json, aliases: '-j'
      def submit(filename)
        job_file = File.expand_path(filename)
        raise 'Cannot open file' unless File.exist?(job_file)

        job_type = if options[:yaml]
                     'yaml'
                   elsif options[:json]
                     'json'
                   else
                     # Detect format
                     match = job_file.match(/\A.*\.(json|yml|yaml)\z/)
                     match[1]
                   end
        job_type = 'yaml' if job_type == 'yml'

        # Do a client-side sanity check by attempting to parse the file; we
        # don't do anything with the data but it fails-fast if the file has a
        # syntax error
        job = File.read(job_file)
        if job_type == 'yaml'
          YAML.load(job)
        elsif job_type == 'json'
          JSON.parse(job)
        else
          raise 'Unknown or unsupported file type'
        end

        job_info = client.job_submit(client.config.organization, job, job_type)
        Formatter.colorize 'Job', job_info['job_id'].to_s
      rescue StandardError => ex
        abort "Failed to submit job: #{ex}"
      end

      desc 'show JOBID', 'Show details of a job'
      def show(jobid)
        job = client.job_get(client.config.organization, jobid)

        status_id = job['status']
        status = Cyclid::API::Constants::JOB_STATUSES[status_id]

        started = job['started'].nil? ? nil : Time.parse(job['started'])
        ended = job['ended'].nil? ? nil : Time.parse(job['ended'])

        # Calculate the duration if the job contains a valid start & end time
        duration = (Time.new(0) + (ended - started) if started && ended)

        # Pretty-print the job details (without the log)
        Formatter.colorize 'Job', job['id'].to_s
        Formatter.colorize 'Name', (job['job_name'] || '')
        Formatter.colorize 'Version', (job['job_version'] || '')
        Formatter.colorize 'Started', (started ? started.asctime : '')
        Formatter.colorize 'Ended', (ended ? ended.asctime : '')
        Formatter.colorize 'Duration', duration.strftime('%H:%M:%S') if duration
        Formatter.colorize 'Status', status
      rescue StandardError => ex
        abort "Failed to get job status: #{ex}"
      end

      desc 'status JOBID', 'Show the status of a job'
      def status(jobid)
        job_status = client.job_status(client.config.organization, jobid)

        status_id = job_status['status']
        status = Cyclid::API::Constants::JOB_STATUSES[status_id]

        # Pretty-print the job status
        Formatter.colorize 'Status', status
      rescue StandardError => ex
        abort "Failed to get job status: #{ex}"
      end

      desc 'log JOBID', 'Show the job log'
      def log(jobid)
        job_log = client.job_log(client.config.organization, jobid)

        puts job_log['log']
      rescue StandardError => ex
        abort "Failed to get job log: #{ex}"
      end

      desc 'list', 'List all jobs'
      def list
        stats = client.job_stats(client.config.organization)
        all = client.job_list(client.config.organization, limit: stats['total'])
        jobs = all['records']

        jobs.each do |job|
          Formatter.colorize 'Name', (job['job_name'] || '')
          Formatter.colorize "\tJob", job['id'].to_s
          Formatter.colorize "\tVersion", (job['job_version'] || '')
        end
      rescue StandardError => ex
        abort "Failed to get job list: #{ex}"
      end

      desc 'stats', 'Show statistics about jobs'
      def stats
        stats = client.job_stats(client.config.organization)

        Formatter.colorize 'Total jobs', stats['total'].to_s
      rescue StandardError => ex
        abort "Failed to get job list: #{ex}"
      end
    end
  end
end
