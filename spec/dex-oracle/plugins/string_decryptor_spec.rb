require 'spec_helper'

describe StringDecryptor do
  let(:data_path) { 'spec/data/plugins' }
  let(:driver) { instance_double('Driver') }
  let(:smali_files) { [SmaliFile.new(file_path)] }
  let(:method) { smali_files.first.methods.first }
  let(:batch) { { id: '123' } }
  let(:plugin) { StringDecryptor.new(driver, smali_files, [method]) }

  describe '#process' do
    subject { plugin.process }

    context 'with string_decrypt.smali' do
      let(:file_path) { "#{data_path}/string_decrypt.smali" }
      let(:batch_item) { ["const-string v0, \"encrypted\"\n\n    invoke-static {v0}, Lorg/cf/StringDecrypt;->decrypt(Ljava/lang/String;)Ljava/lang/String;\n\n    move-result-object v0", 'v0'] }

      it do
        expect(driver).to receive(:make_target).with('org/cf/StringDecrypt', 'decrypt(Ljava/lang/String;)', 'encrypted').and_return(batch)
        expect(Plugin).to receive(:apply_batch).with(driver, { method => { batch => [batch_item] } }, kind_of(Proc))
        subject
      end
    end
  end
end
