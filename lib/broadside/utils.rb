module Broadside
  module Utils
    def debug(*args)
      config.base.logger.debug(args.join(' '))
    end

    def info(*args)
      config.base.logger.info(args.join(' '))
    end

    def warn(*args)
      config.base.logger.warn(args.join(' '))
    end

    def error(*args)
      config.base.logger.error(args.join(' '))
    end

    def exception(*args)
      raise Broadside::Error, args.join("\n")
    end

    def gen_ssh_cmd(ip, ssh_config, options = { tty: false })
      cmd = 'ssh -o StrictHostKeyChecking=no'
      cmd << ' -t -t' if options[:tty]
      cmd << " -i #{ssh_config[:keyfile]}" if ssh_config[:keyfile]
      if ssh_config[:proxy]
        proxy = ssh_config[:proxy][:user] ? "#{ssh_config[:proxy][:user]}@#{ssh_config[:proxy][:host]}" : ssh_config[:proxy][:host]
        proxy << " -i #{ssh_config[:proxy][:keyfile]}" if ssh_config[:proxy][:keyfile]

        cmd << " -o ProxyCommand=\"ssh -q #{proxy} nc #{ip} #{ssh_config[:proxy][:port]}\""
      end
      cmd << " #{ssh_config[:user]}@#{ip}"
      cmd
    end

    def config
      Broadside.config
    end
  end
end
