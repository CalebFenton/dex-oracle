require 'spec_helper'

describe Driver do
    let(:temp_file) { '/fake/tmp/file' }
    let(:driver) {
        allow(Tempfile).to receive(:new).and_return(temp_file)
        allow(File).to receive(:open).and_yield(temp_file)
        allow(temp_file).to receive(:path).and_return(temp_file)
        allow(temp_file).to receive(:unlink)
        allow(temp_file).to receive(:close)
        allow(temp_file).to receive(:write)
        Driver.new(device_id)
    }

    describe '#add_batch_item' do
        let(:device_id) { '' }
        let(:batch) { [] }
        let(:add_batch_item) { driver.add_batch_item(batch, class_name, method_signature, *args) }

        let(:class_name) { 'some/Klazz' }
        let(:method_signature) { 'run(III)V' }
        let(:args) { [1,2,3] }

        subject { batch }
        it {
            add_batch_item
            should eq [{:className=>"some.Klazz", :methodName=>"run", :arguments=>["'I:1'", "'I:2'", "'I:3'"]}]
        }
    end

    describe '#run_batch' do
        let(:device_id) { '' }
        let(:batch) { [{:className=>"some.Klazz", :methodName=>"run", :arguments=>["'I:1'", "'I:2'", "'I:3'"]}] }
        let(:run_batch) { driver.run_batch(batch) }

        subject { run_batch }
        it {
            allow(driver).to receive(:exec)
            allow(driver).to receive(:exec_no_cache)

            expect(temp_file).to receive(:write).with(batch.to_json).ordered
            expect(driver).to receive(:exec_no_cache).with(
                "adb push #{temp_file} /data/local/od-targets.json"
            ).ordered
            expect(driver).to receive(:exec_no_cache).with(
                "adb shell \"export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.oracle.Driver @/data/local/od-targets.json\"; echo $?"
            ).ordered
            subject
        }
    end

    describe '#run_single' do
        context 'with a device id' do
            let(:device_id) { '1234abcd' }

            context 'with integer arguments' do
                let(:class_name) { 'some/Klazz' }
                let(:method_signature) { 'run(III)V' }
                let(:args) { [1,2,3] }

                subject { driver.run_single(class_name, method_signature, *args) }
                it {
                    allow(driver).to receive(:exec)
                    allow(driver).to receive(:exec_no_cache)

                    expect(driver).to receive(:exec).with(
                        "adb shell -s #{device_id} \"export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.oracle.Driver 'some.Klazz' 'run' 'I:1' 'I:2' 'I:3'\"; echo $?"
                    )
                    subject
                }
            end
        end

        context 'without a device id' do
            let(:device_id) { '' }

            context 'with string argument' do
                let(:class_name) { 'string/Klazz' }
                let(:method_signature) { 'run(Ljava/lang/String;)V' }
                let(:args) { 'hello string' }

                subject { driver.run_single(class_name, method_signature, args) }
                it {
                    allow(driver).to receive(:exec)
                    allow(driver).to receive(:exec_no_cache)

                    expect(driver).to receive(:exec).with(
                        "adb shell \"export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.oracle.Driver 'string.Klazz' 'run' 'java.lang.String:[104,101,108,108,111,32,115,116,114,105,110,103]'\"; echo $?"
                    )
                    subject
                }
            end
        end
    end
end
