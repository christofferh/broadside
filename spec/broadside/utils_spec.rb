require 'spec_helper'

module Broadside
  describe Utils do
    let(:c) { Class.new { extend Utils } }

    describe '#gen_ssh_cmd' do
      let(:ip) { '127.0.0.1' }
      let(:user) { 'test-user' }
      let(:ssh_config) do
        {
          user: user,
        }
      end

      it 'generates an ssh command string' do
        expect(c.gen_ssh_cmd(ip, ssh_config)).to eq(
          "ssh -o StrictHostKeyChecking=no #{user}@#{ip}"
        )
      end

      context 'with tty option' do
        it 'generates an ssh command string with -tt flags' do
          expect(c.gen_ssh_cmd(ip, ssh_config, tty: true)).to eq(
            "ssh -o StrictHostKeyChecking=no -t -t #{user}@#{ip}"
          )
        end
      end

      context 'with ssh keyfile provided in the ssh config' do
        let(:keyfile) { 'path_to_keyfile' }
        let(:ssh_config_keyfile) { ssh_config.merge({keyfile: keyfile}) }

        it 'generates an ssh command string with the -i flag' do
          expect(c.gen_ssh_cmd(ip, ssh_config_keyfile)).to eq(
            "ssh -o StrictHostKeyChecking=no -i #{keyfile} #{user}@#{ip}"
          )
        end
      end

      context 'with ssh proxy' do
        let(:proxy_user) { 'proxy-user' }
        let(:proxy_host) { 'proxy-host' }
        let(:proxy_port) { '22' }
        let(:proxy_keyfile) { 'path_to_proxy_keyfile' }
        let(:ssh_config_proxy) do
          {
            proxy: {
              user: proxy_user,
              host: proxy_host,
              port: proxy_port,
              keyfile: proxy_keyfile
            }
          }.merge(ssh_config)
        end

        it 'generates an ssh command string with the configured ssh proxy' do
          expect(c.gen_ssh_cmd(ip, ssh_config_proxy)).to eq(
            "ssh -o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -q #{proxy_user}@#{proxy_host} -i #{proxy_keyfile} nc #{ip} #{proxy_port}\" #{user}@#{ip}"
          )
        end
      end
    end
  end
end
