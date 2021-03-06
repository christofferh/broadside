require 'pp'
require 'shellwords'
require 'tty-table'

module Broadside
  module Command
    extend LoggingUtils

    DEFAULT_TAIL_LINES = 10

    class << self
      def targets
        table_header = nil
        table_rows = []

        Broadside.config.targets.sort.each do |_, target|
          task_definition = EcsManager.get_latest_task_definition(target.family)
          service_tasks_running = EcsManager.get_task_arns(
            target.cluster,
            target.family,
            service_name: target.family,
            desired_status: 'RUNNING'
          ).size

          if task_definition.nil?
            warn "Skipping deploy target '#{target.name}' as it does not have a configured task_definition."
            next
          end

          container_definitions = task_definition[:container_definitions].select { |c| c[:name] == target.family }
          warn "Only displaying 1/#{container_definitions.size} containers" if container_definitions.size > 1
          container_definition = container_definitions.first

          row_data = target.to_h.merge(
            Image: container_definition[:image],
            CPU: container_definition[:cpu],
            Memory: container_definition[:memory],
            Revision: task_definition[:revision],
            Tasks: "#{service_tasks_running}/#{target.scale}"
          )

          table_header ||= row_data.keys.map(&:to_s)
          table_rows << row_data.values
        end

        table = TTY::Table.new(header: table_header, rows: table_rows)
        puts table.render(:ascii, padding: [0, 1])
      end

      def status(options)
        target = Broadside.config.get_target_by_name!(options[:target])
        cluster = target.cluster
        family = target.family
        pastel = Pastel.new
        debug "Getting status information about #{family}"

        output = [
          pastel.underline('Current task definition information:'),
          pastel.blue(PP.pp(EcsManager.get_latest_task_definition(family), ''))
        ]

        if options[:verbose]
          output << [
            pastel.underline('Current service information:'),
            pastel.bright_blue(PP.pp(EcsManager.ecs.describe_services(cluster: cluster, services: [family]), ''))
          ]
        end

        task_arns = EcsManager.get_task_arns(cluster, family)
        if task_arns.empty?
          output << ["No running tasks found.\n"]
        else
          ips = EcsManager.get_running_instance_ips(cluster, family)

          if options[:verbose]
            output << [
              pastel.underline('Task information:'),
              pastel.bright_cyan(PP.pp(EcsManager.ecs.describe_tasks(cluster: cluster, tasks: task_arns), ''))
            ]
          end

          output << [
            pastel.underline('Private IPs of instances running tasks:'),
            pastel.cyan(ips.map { |ip| "#{ip}: #{Broadside.config.ssh_cmd(ip)}" }.join("\n")) + "\n"
          ]
        end

        puts output.join("\n")
      end

      def logtail(options)
        lines = options[:lines] || DEFAULT_TAIL_LINES
        target = Broadside.config.get_target_by_name!(options[:target])
        ip = get_running_instance_ip!(target, *options[:instance])
        info "Tailing logs for running container at #{ip}..."

        cmd = "docker logs -f --tail=#{lines} `#{docker_ps_cmd(target.family)}`"
        exec(Broadside.config.ssh_cmd(ip) + " '#{cmd}'")
      end

      def ssh(options)
        target = Broadside.config.get_target_by_name!(options[:target])
        ip = get_running_instance_ip!(target, *options[:instance])
        info "Establishing SSH connection to #{ip}..."

        exec(Broadside.config.ssh_cmd(ip))
      end

      def bash(options)
        target = Broadside.config.get_target_by_name!(options[:target])
        ip = get_running_instance_ip!(target, *options[:instance])
        info "Running bash for running container at #{ip}..."

        cmd = "docker exec -i -t `#{docker_ps_cmd(target.family)}` bash"
        exec(Broadside.config.ssh_cmd(ip, tty: true) + " '#{cmd}'")
      end

      private

      def get_running_instance_ip!(target, instance_index = 0)
        EcsManager.check_service_and_task_definition_state!(target)
        EcsManager.get_running_instance_ips!(target.cluster, target.family).fetch(instance_index)
      end

      def docker_ps_cmd(family)
        "docker ps -n 1 --quiet --filter name=#{Shellwords.shellescape(family)}"
      end
    end
  end
end
