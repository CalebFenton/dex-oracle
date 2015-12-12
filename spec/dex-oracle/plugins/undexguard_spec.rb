require 'spec_helper'

describe Undexguard do
    let(:data_path) { 'spec/data/undexguard' }
    let(:smali_files) { [SmaliFile.new(file_path)] }
    let(:method) { smali_files.first.methods.first }
    let(:driver) { instance_double('Driver') }
    let(:outputs) { {method => 1} }
    let(:batch) { {:id => '123'} }

    describe '.lookup_strings_3int' do
        let(:file_path) { "#{data_path}/string_lookup_3int.smali" }
        subject { Undexguard.lookup_strings_3int(driver, method) }
        it {
            expect(driver).to receive(:make_target).with('org/cf/StringLookup', 'lookup(III)', 0, 1, 2).and_return(batch)
            should == {batch => [["const/4 v0, 0x0\n\n    const/4 v1, 0x1\n\n    const/4 v2, 0x2\n\n    invoke-static {v0, v1, v2}, Lorg/cf/StringLookup;->lookup(III)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}
        }
    end

    describe '.lookup_strings_1int' do
        let(:file_path) { "#{data_path}/string_lookup_1int.smali" }
        subject { Undexguard.lookup_strings_1int(driver, method) }
        it {
            expect(driver).to receive(:make_target).with('org/cf/StringLookup', 'lookup(I)', 0).and_return(batch)
            should == {batch => [["const/4 v0, 0x0\n\n    invoke-static {v0}, Lorg/cf/StringLookup;->lookup(I)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}
        }
    end

    describe '.decrypt_strings' do
        let(:file_path) { "#{data_path}/string_decrypt.smali" }
        subject { Undexguard.decrypt_strings(driver, method) }
        it {
            expect(driver).to receive(:make_target).with('org/cf/StringDecrypt', 'decrypt(Ljava/lang/String;)', 'encrypted').and_return(batch)
            should == {batch => [["const-string v0, \"encrypted\"\n\n    invoke-static {v0}, Lorg/cf/StringDecrypt;->decrypt(Ljava/lang/String;)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}
        }
    end
end
