require 'spec_helper'

describe IndexedClassLookup do
  let(:data_path) { 'spec/data/plugins' }
  let(:driver) { instance_double('Driver') }
  let(:smali_files) { [SmaliFile.new(file_path)] }
  let(:method) { smali_files.first.methods.first }
  let(:batch) { { id: '123' } }
  let(:plugin) { IndexedClassLookup.new(driver, smali_files, [method]) }

  describe '#process' do
    subject { plugin.process }

    context 'with class_lookup.smali' do
      let(:file_path) { "#{data_path}/class_lookup.smali" }
      let(:batch_item) { ["const v0, 0x19189b0e\n\n    :some_label\n    invoke-static {v0}, Lxjmurla/gqscntaej/bfdiays/g;->c(I)Ljava/lang/Class;\n\n    move-result-object v0", 'v0'] }

      it do
        expect(driver).to receive(:make_target).with('xjmurla/gqscntaej/bfdiays/g', 'c(I)', 421042958).and_return(batch)
        expect(Plugin).to receive(:apply_batch).with(driver, { method => { batch => [batch_item] } }, kind_of(Proc), kind_of(Proc))
        subject
      end
    end
  end
end
