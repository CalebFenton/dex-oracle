require 'spec_helper'

describe Undexguard do
    let(:data_path) { 'spec/data' }
    let(:smali_file) { SmaliFile.new(file_path) }
    let(:driver) { instance_double("Driver") }

    describe 'string lookups' do
        let(:file_path) { "#{data_path}/string_lookup.smali" }
        subject { smali_file.methods.first }
        its(:body) {
            allow(driver).to receive(:run) { '"looked up"' }
            expect(driver).to receive(:run).with('org/cf/StringLookup', 'lookup', 0, 1, 2)
            Undexguard.process(driver, smali_file)
            should eq "\n    .locals 3\n\n    const-string v0, \"looked up\"\n\n    return-void\n"
        }
    end
end
