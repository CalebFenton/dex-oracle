require 'spec_helper'

describe Undexguard do
    let(:data_path) { 'spec/data/undexguard' }
    let(:driver) { instance_double('Driver') }
    let(:smali_files) { [SmaliFile.new(file_path)] }
    let(:method) { smali_files.first.methods.first }
    let(:batch) { {:id => '123'} }
    let(:plugin) { Undexguard.new(driver, smali_files, [method])}

    describe '#process' do
        subject { plugin.process }

        context 'with string_lookup_3int.smali' do
            let(:file_path) { "#{data_path}/string_lookup_3int.smali" }

            it {
                expect(driver).to receive(:make_target).with('org/cf/StringLookup', 'lookup(III)', 0, 1, 2).and_return(batch)
                expect(Plugin).to receive(:apply_batch).with(
                    driver, {method => {batch => [["const/4 v0, 0x0\n\n    const/4 v1, 0x1\n\n    const/4 v2, 0x2\n\n    invoke-static {v0, v1, v2}, Lorg/cf/StringLookup;->lookup(III)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}}, kind_of(Proc)
                )
                subject
            }
        end

        context 'with string_lookup_1int.smali' do
            let(:file_path) { "#{data_path}/string_lookup_1int.smali" }

            it {
                expect(driver).to receive(:make_target).with('org/cf/StringLookup', 'lookup(I)', 0).and_return(batch)
                expect(Plugin).to receive(:apply_batch).with(
                    driver, {method => {batch => [["const/4 v0, 0x0\n\n    invoke-static {v0}, Lorg/cf/StringLookup;->lookup(I)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}}, kind_of(Proc)
                )
                subject
            }
        end

        context 'with string_decrypt.smali' do
            let(:file_path) { "#{data_path}/string_decrypt.smali" }

            it {
                expect(driver).to receive(:make_target).with('org/cf/StringDecrypt', 'decrypt(Ljava/lang/String;)', 'encrypted').and_return(batch)
                expect(Plugin).to receive(:apply_batch).with(
                    driver, {method => {batch => [["const-string v0, \"encrypted\"\n\n    invoke-static {v0}, Lorg/cf/StringDecrypt;->decrypt(Ljava/lang/String;)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}}, kind_of(Proc)
                )
                subject
            }
        end
    end
end
