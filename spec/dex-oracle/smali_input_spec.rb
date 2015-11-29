require 'spec_helper'

describe SmaliInput do
    DATA_PATH = 'spec/data'
    TEMP_DIR = '/fake/tmp/dir'

    context 'for input that must be disassembled with baksmali' do
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(TEMP_DIR)
            allow(SmaliInput).to receive(:which).and_return('baksmali')
            allow(SmaliInput).to receive(:run)
            SmaliInput.new(file_path)
        end
        subject { smali }

        context 'with an apk' do
            let(:file_path) { "#{DATA_PATH}/helloworld.apk" }
            its(:temporary) { should eq true }
            its(:dir) { should eq TEMP_DIR }
        end

        context 'with a dex' do
            let(:file_path) { "#{DATA_PATH}/helloworld.dex" }
            its(:temporary) { should eq true }
            its(:dir) { should eq TEMP_DIR }
        end
    end

    context 'for input that must be disassembled without baksmali' do
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(TEMP_DIR)
            allow(SmaliInput).to receive(:which).and_return(nil)
            allow(SmaliInput).to receive(:run)
            SmaliInput.new(file_path)
        end
        subject { smali }

        it 'raises' do
            expect raise_error
        end
    end

    context 'for unrecognized input type' do
        let(:file_path) { "#{DATA_PATH}/helloworld.smali" }
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(TEMP_DIR)
            SmaliInput.new(file_path)
        end
        subject { smali }

        it 'raises' do
            expect raise_error
        end
    end

    context 'for a directory' do
        let(:file_path) { DATA_PATH }
        let(:smali) { SmaliInput.new(file_path) }
        subject { smali }
        its(:temporary) { should eq false }
        its(:dir) { should eq DATA_PATH }
    end
end
