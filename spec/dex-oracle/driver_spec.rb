require 'spec_helper'

describe Driver do
    let(:driver_dir) { '/data/local' }
    let(:driver) { Driver.new(driver_dir, device_id, use_dvz) }

    describe "#run" do
        context 'using dalvikvm with a device id' do
            let(:use_dvz) { false }
            let(:device_id) { '1234abcd' }

            context 'with integer arguments' do
                let(:class_name) { 'some/Klazz' }
                let(:method_signature) { 'run(III)V' }
                let(:args) { [1,2,3] }

                subject { driver.run(class_name, method_signature, *args) }
                it {
                    allow(driver).to receive(:exec)
                    expect(driver).to receive(:exec).with(
                        "adb shell dalvikvm -cp /data/local OracleDriver some.Klazz run(III)V 'I:1' 'I:2' 'I:3'"
                    )
                    subject
                }
            end
        end

        context 'using dvz without a device id' do
            let(:use_dvz) { true }
            let(:device_id) { '' }
            context 'with string argument' do
                let(:class_name) { 'string/Klazz' }
                let(:method_signature) { 'run(Ljava/lang/String;)V' }
                let(:args) { 'hello string' }

                subject { driver.run(class_name, method_signature, args) }
                it {
                    allow(driver).to receive(:exec)
                    expect(driver).to receive(:exec).with(
                        "adb shell dvz -classpath /data/local OracleDriver string.Klazz run(Ljava/lang/String;)V 'java.lang.String:[104,101,108,108,111,32,115,116,114,105,110,103]'"
                    )
                    subject
                }
            end
        end
    end

end
