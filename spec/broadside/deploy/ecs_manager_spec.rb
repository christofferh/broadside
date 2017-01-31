require 'spec_helper'

# Hitting the stubbed Aws::ECS::Client object will validate the request format

describe Broadside::EcsManager do
  let(:service_name) { 'service' }
  let(:cluster) { 'cluster' }
  let(:name) { 'job' }

  let(:ecs_stub) do
    Aws::ECS::Client.new(
      region: Broadside.config.aws.region,
      credentials: Aws::Credentials.new('access', 'secret'),
      stub_responses: true
    )
  end

  before(:each) { Broadside::EcsManager.instance_variable_set(:@ecs_client, ecs_stub) }

  describe '#create_service' do
    it 'creates an ECS service from the given configs' do
      expect { described_class.create_service(cluster, service_name) }.to_not raise_error
    end

    it 'supports creating an ECS service with an ALB' do

    end
  end

  describe '#list_services' do
    it 'returns an array of services belonging to the provided cluster' do
      expect { described_class.list_services(cluster) }.to_not raise_error
    end
  end

  describe '#get_task_arns' do
    it 'returns an array of task arns belonging to a provided cluster with the provided name' do
      expect { described_class.get_task_arns(cluster, name) }.to_not raise_error
    end
  end

  describe '#get_task_definition_arns' do
    it 'returns an array of task definition arns with the provided name' do
      expect { described_class.get_task_definition_arns(name) }.to_not raise_error
      expect { described_class.get_latest_task_definition_arn(name) }.to_not raise_error
    end
  end

  describe '#get_latest_task_definition' do
    it 'returns the most recent valid task definition' do
      expect(described_class.get_latest_task_definition(name)).to be_nil
    end
  end

  describe '#task_revision_merge' do
    let(:app_container_def) do
      {
        name: 'app_testing_web',
        image: 'test-image',
        cpu: 99,
        memory: 99,
        environment: [{
            name: 'TESTKEY',
            value: 'TESTVAL'
        }]
      }
    end
    let(:old_task_rev) do
      {
        family: 'test-family',
        container_definitions: [
          app_container_def,
          {
            name: 'some_other_name',
            image: 'some_other_image'
          }
        ],
        volumes: [{
          name: 'test-volume'
        }]
      }
    end
    let(:new_task_rev) do
      {
        family: 'test-family',
        container_definitions: [
          {
            name: 'app_testing_web',
            image: 'test-image-new',
            cpu: 100,
            memory: 100,
            environment: [{
                name: 'NEWKEY',
                value: 'NEWVAL'
            }]
          },
        ]
      }
    end
    it 'merges two task definition revisions' do

    end

    it 'merges/injects the configurations of a custom container definition specified in the new revision with the old revision' do

    end
  end

  context 'all_results' do
    let(:task_definition_arns) { ["arn:task-definition/task:1", "arn:task-definition/other_task:1" ] }
    let(:stub_task_definition_responses) do
      [
        { task_definition_arns: [task_definition_arns[0]], next_token: 'MzQ3N' },
        { task_definition_arns: [task_definition_arns[1]] }
      ]
    end

    before do
      ecs_stub.stub_responses(:list_task_definitions, stub_task_definition_responses)
    end

    it 'can pull multipage results' do
      expect(described_class.get_task_definition_arns('task')).to eq(task_definition_arns)
    end
  end
end
