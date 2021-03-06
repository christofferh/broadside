require 'spec_helper'

describe Broadside::Target do
  include_context 'deploy configuration'

  let(:base_possible_options) do
    {
      bootstrap_commands: [],
      cluster: 'some-cluster',
      command: %w(some command),
      docker_image: 'lumoslabs/hello',
      env_file: '.env.test',
      predeploy_commands: [],
      scale: 9000,
      service_config: {},
      tag: 'latest',
      task_definition_config: {}
    }
  end
  let(:all_possible_options) { base_possible_options }
  let(:all_possible_options_with_create_only_service_options) { base_possible_options }
  let(:target) { described_class.new(test_target_name, all_possible_options) }

  describe '#initialize' do
    it 'should initialize without erroring using all possible options' do
      expect { target }.to_not raise_error
    end
  end

  shared_examples 'valid_configuration?' do |succeeds, config_hash|
    let(:valid_options) { { scale: 100 } }
    let(:target) { described_class.new(test_target_name, valid_options.merge(config_hash)) }

    it 'validates target configuration' do
      if succeeds
        expect { target }.to_not raise_error
      else
        expect { target }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#validate_targets!' do
    it_behaves_like 'valid_configuration?', true, {}

    it_behaves_like 'valid_configuration?', false, scale: 1.1
    it_behaves_like 'valid_configuration?', false, scale: nil

    it_behaves_like 'valid_configuration?', true,  env_files: nil
    it_behaves_like 'valid_configuration?', true,  env_files: 'file'
    it_behaves_like 'valid_configuration?', true,  env_files: %w(file file2)

    it_behaves_like 'valid_configuration?', true,  command: nil
    it_behaves_like 'valid_configuration?', true,  command: %w(do something)
    it_behaves_like 'valid_configuration?', false, command: 'do something'

    it_behaves_like 'valid_configuration?', true,  predeploy_commands: nil
    it_behaves_like 'valid_configuration?', false, predeploy_commands: %w(do something)
    it_behaves_like 'valid_configuration?', true,  predeploy_commands: [%w(do something)]
    it_behaves_like 'valid_configuration?', true,  predeploy_commands: [%w(do something), %w(other command)]

    it_behaves_like 'valid_configuration?', false,  task_definition_config: { container_definitions: %w(a b) }
  end

  describe '#ecs_env_vars' do
    let(:valid_options) { { scale: 1, env_files: env_files } }
    let(:target) { described_class.new(test_target_name, valid_options) }
    let(:dot_env_file) { File.join(FIXTURES_PATH, '.env.rspec') }

    shared_examples 'successfully loaded env_files' do
      it 'loads environment variables from a file' do
        expect(target.ecs_env_vars).to eq(expected_env_vars)
      end
    end

    context 'with a single environment file' do
      let(:env_files) { dot_env_file }
      let(:expected_env_vars) do
        [
          { 'name' => 'TEST_KEY1', 'value' => 'TEST_VALUE1' },
          { 'name' => 'TEST_KEY2', 'value' => 'TEST_VALUE2' }
        ]
      end

      it_behaves_like 'successfully loaded env_files'
    end

    context 'with multiple environment files' do
      let(:env_files) { [dot_env_file, dot_env_file + '.override'] }
      let(:expected_env_vars) do
        [
          { 'name' => 'TEST_KEY1', 'value' => 'TEST_VALUE1' },
          { 'name' => 'TEST_KEY2', 'value' => 'TEST_VALUE_OVERRIDE' },
          { 'name' => 'TEST_KEY3', 'value' => 'TEST_VALUE3' }
        ]
      end

      it_behaves_like 'successfully loaded env_files'
    end
  end

  describe '#service_config_for_update' do
    context 'with no service config' do
      it 'does not raise an error' do
        expect { target }.to_not raise_error
      end
    end

    shared_examples 'accessor for update-safe service config parameters' do
      it 'does not raise an error' do
        expect { target }.to_not raise_error
      end

      it 'returns the basic serivce config parameters' do
        expect(target.service_config).to eq(base_possible_options[:service_config])
      end
    end

    context 'with a normal service config' do
      it_behaves_like 'accessor for update-safe service config parameters'
    end

    context 'with a service config containing create-only parameters' do
      let(:all_possible_options) { all_possible_options_with_create_only_service_options }

      it_behaves_like 'accessor for update-safe service config parameters'
    end
  end
end
