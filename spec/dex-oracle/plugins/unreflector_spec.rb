require 'spec_helper'

describe Unreflector do
    let(:data_path) { 'spec/data/plugins' }
    let(:driver) { instance_double('Driver') }
    let(:smali_files) { [SmaliFile.new(file_path)] }
    let(:method) { smali_files.first.methods.first }
    let(:batch) { {:id => '123'} }
    let(:plugin) { Unreflector.new(driver, smali_files, [method])}

    describe '#process' do
        subject { plugin.process }

        context 'with class_forname.smali' do
            let(:file_path) { "#{data_path}/class_forname.smali" }

            it {
                expect(Plugin).to receive(:apply_outputs).with(
                    {'f8dc3df1acedbee81e5ff984eb026b76eb5e4bdf6d401fb12e081b8bcdb0cd55'=>['success', 'Landroid/content/Intent;']},
                    {method => {{:id=>'f8dc3df1acedbee81e5ff984eb026b76eb5e4bdf6d401fb12e081b8bcdb0cd55'}=>[["const-string v0, \"android.content.Intent\"\n\n    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;\n\n    move-result-object v0", "v0"]]}},
                    kind_of(Proc)
                )
                subject
            }
        end
    end
end
