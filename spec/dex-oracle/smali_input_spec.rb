require 'spec_helper'

describe SmaliInput do
    let(:data_path) { 'spec/data' }
    let(:temp_dir) { '/fake/tmp/dir' }

    context 'for input that must be disassembled with baksmali' do
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
            allow(SmaliInput).to receive(:which).and_return('baksmali')
            allow(SmaliInput).to receive(:run)
            SmaliInput.new(file_path)
        end
        subject { smali }

        context 'with an apk' do
            let(:file_path) { "#{data_path}/helloworld.apk" }
            its(:temporary) { should eq true }
            its(:dir) { should eq temp_dir }
        end

        context 'with a dex' do
            let(:file_path) { "#{data_path}/helloworld.dex" }
            its(:temporary) { should eq true }
            its(:dir) { should eq temp_dir }
        end
    end

    context 'for input that must be disassembled without baksmali' do
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
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
        let(:file_path) { "#{data_path}/helloworld.smali" }
        let(:smali) do
            allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
            SmaliInput.new(file_path)
        end
        subject { smali }

        it 'raises' do
            expect raise_error
        end
    end

    context 'for a directory' do
        let(:file_path) { "#{data_path}/smali" }
        let(:smali) { SmaliInput.new(file_path) }
        subject { smali }
        its(:temporary) { should eq false }
        its(:dir) { should eq file_path }
    end
end
