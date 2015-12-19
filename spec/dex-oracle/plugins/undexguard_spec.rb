require 'spec_helper'

describe Undexguard do
    let(:data_path) { 'spec/data/plugins' }
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

        context 'with bytes_decrypt.smali' do
            let(:file_path) { "#{data_path}/bytes_decrypt.smali" }

            it {
                expect(driver).to receive(:make_target).with('org/cf/BytesDecrypt', 'decrypt([B)', [97, 115, 100, 102]).and_return(batch)
                expect(Plugin).to receive(:apply_batch).with(
                    driver, {method => {batch => [["const-string v0, \"asdf\"\n\n    invoke-virtual {v0}, Ljava/lang/String;->getBytes()[B\n\n    move-result-object v0\n\n    invoke-static {v0}, Lorg/cf/BytesDecrypt;->decrypt([B)Ljava/lang/String;\n\n    move-result-object v0", "v0"]]}}, kind_of(Proc)
                )
                subject
            }
        end

        context 'with multi_bytes_decrypt.smali' do
            let(:file_path) { "#{data_path}/multi_bytes_decrypt.smali" }
            let(:iv_bytes) { '[1,2,3]' }
            let(:enc_bytes) { '[4,5,6]' }
            let(:dec_bytes) { '[65]' }
            it {
                expect(driver).to receive(:run).with('org/cf/MultiBytesDecrypt', 'doThing1(Ljava/lang/String;)', 'string1').and_return(iv_bytes)
                expect(driver).to receive(:run).with('org/cf/MultiBytesDecrypt', 'doThing2([BLjava/lang/String;)', iv_bytes, 'string2').and_return(enc_bytes)
                expect(driver).to receive(:run).with('org/cf/MultiBytesDecrypt', 'doThing3([B)', enc_bytes).and_return(dec_bytes)
                expect(Plugin).to receive(:apply_outputs).with(
                    {'9e31b050ec6334ed1c9ec57686b5bd765bd811410bc240141dfc466ef0719bfd'=>['success', 'A']},
                    {method => {{:id=>'9e31b050ec6334ed1c9ec57686b5bd765bd811410bc240141dfc466ef0719bfd'}=>[["const-string v0, \"string1\"\n\n    new-instance v1, Ljava/lang/String;\n\n    invoke-static {v0}, Lorg/cf/MultiBytesDecrypt;->doThing1(Ljava/lang/String;)[B\n\n    move-result-object v2\n\n    const-string v3, \"string2\"\n\n    invoke-static {v2, v3}, Lorg/cf/MultiBytesDecrypt;->doThing2([BLjava/lang/String;)[B\n\n    move-result-object v2\n\n    invoke-static {v2}, Lorg/cf/MultiBytesDecrypt;->doThing3([B)[B\n\n    move-result-object v2\n\n    invoke-direct {v1, v2}, Ljava/lang/String;-><init>([B)V", "v1"]]}},
                    kind_of(Proc)
                )
                subject
            }
        end
    end
end
