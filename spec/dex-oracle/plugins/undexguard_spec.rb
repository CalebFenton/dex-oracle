require 'spec_helper'

describe Undexguard do
    let(:data_path) { 'spec/data/undexguard' }
    let(:smali_file) { SmaliFile.new(file_path) }
    let(:driver) { instance_double("Driver") }

    describe 'string lookups with 3 int' do
        let(:file_path) { "#{data_path}/string_lookup_3int.smali" }
        subject { smali_file.methods.first }
        its(:body) {
            allow(driver).to receive(:run_single).and_return('"looked up"')
            expect(driver).to receive(:run_single).with('org/cf/StringLookup', 'lookup(III)', 0, 1, 2)
            Undexguard.process(driver, smali_file)
            should eq "\n    .locals 3\n\n    const-string v0, \"looked up\"\n\n    return-void\n"
        }
    end

    describe 'string lookups with 1 int' do
        let(:file_path) { "#{data_path}/string_lookup_1int.smali" }
        subject { smali_file.methods.first }
        its(:body) {
            allow(driver).to receive(:run_single).and_return('"looked up"')
            expect(driver).to receive(:run_single).with('org/cf/StringLookup', 'lookup(I)', 0)
            Undexguard.process(driver, smali_file)
            should eq "\n    .locals 1\n\n    const-string v0, \"looked up\"\n\n    return-void\n"
        }
    end

    describe 'string decryption' do
        let(:file_path) { "#{data_path}/string_decrypt.smali" }
        subject { smali_file.methods.first }
        its(:body) {
            allow(driver).to receive(:run_single).and_return('"decrypted"')
            expect(driver).to receive(:run_single).with('org/cf/StringDecrypt', 'decrypt(Ljava/lang/String;)', 'encrypted')
            Undexguard.process(driver, smali_file)
            should eq "\n    .locals 1\n\n    const-string v0, \"decrypted\"\n\n    return-void\n"
        }
    end
end
