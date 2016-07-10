require 'spec_helper'
require 'fakefs/spec_helpers'

describe SmaliInput do
  include FakeFS::SpecHelpers

  let(:data_path) { 'spec/data' }
  let(:temp_dir) { '/fake/tmp/dir' }
  let(:temp_file) { '/fake/tmp/file' }

  before(:each) do
    FakeFS::FileSystem.clone('spec/data', 'spec/data')
  end

  after(:all) do
  end
  context 'for input that must be disassembled with baksmali' do
    let(:smali_input) do
      allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
      allow(Tempfile).to receive(:new).and_return(temp_file)
      allow(Utility).to receive(:which).and_return('baksmali')
      allow(SmaliInput).to receive(:exec)
      allow(SmaliInput).to receive(:baksmali)
      allow(SmaliInput).to receive(:update_apk)
      allow(SmaliInput).to receive(:extract_dex)
      SmaliInput.new(file_path)
    end

    subject { smali_input }

    context 'with an apk' do
      let(:file_path) { "#{data_path}/helloworld.apk" }
      its(:out_apk) { should eq 'helloworld_oracle.apk' }
      its(:out_dex) { should eq temp_file }
      its(:dir) { should eq temp_dir }
      its(:temp_dir) { should be true }
      its(:temp_dex) { should be true }
    end

    context 'with a dex' do
      let(:file_path) { "#{data_path}/helloworld.dex" }
      its(:out_apk) { should be nil }
      its('out_dex.path') { should eq 'helloworld_oracle.dex' }
      its(:dir) { should eq temp_dir }
      its(:temp_dir) { should be true }
      its(:temp_dex) { should be false }
    end
  end

  context 'for input that must be disassembled without baksmali' do
    let(:file_path) { "#{data_path}/helloworld.dex" }
    let(:smali_input) do
      allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
      allow(SmaliInput).to receive(:which).and_return(nil)
      allow(SmaliInput).to receive(:exec)
      SmaliInput.new(file_path)
    end

    subject { smali_input }
    it 'raises' do
      expect raise_error
    end
  end

  context 'for unrecognized input type' do
    let(:file_path) { "#{data_path}/helloworld.smali" }
    let(:smali_input) do
      allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
      SmaliInput.new(file_path)
    end

    subject { smali_input }

    it 'raises' do
      expect raise_error
    end
  end

  context 'for a directory' do
    let(:file_path) { "#{data_path}/smali" }
    let(:smali_input) do
      allow(FileUtils).to receive(:rm_rf)
      allow(SmaliInput).to receive(:compile)
      SmaliInput.new(file_path)
    end

    subject { smali_input }

    its(:out_apk) { should be nil }
    its(:out_dex) { should be nil }
    its(:dir) { should eq file_path }
    its(:temp_dir) { should be false }
    its(:temp_dex) { should be true }
    it do
      expect(SmaliInput).to receive(:compile)
      subject
    end
  end
end
