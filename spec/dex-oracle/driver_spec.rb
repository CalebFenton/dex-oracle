require 'spec_helper'

describe Driver do
  let(:temp_file) { instance_double('Tempfile') }
  let(:class_name) { 'some/Klazz' }
  let(:method_signature) { 'run(III)V' }
  let(:args) { [1, 2, 3] }
  let(:batch_id) { '8ea0a5c705617449899c85cec2435356e8be83d6829e12ff109ab0c44c4156c6' }
  let(:batch_item) { { className: 'some.Klazz', methodName: 'run', arguments: %w(I:1 I:2 I:3), id: batch_id } }
  let(:driver) do
    allow(temp_file).to receive(:path).and_return('/fake/tmp/file')
    allow(temp_file).to receive(:unlink)
    allow(temp_file).to receive(:close)
    allow(temp_file).to receive(:flush)
    allow(temp_file).to receive(:<<)
    allow(Tempfile).to receive(:new).and_return(temp_file)
    allow(File).to receive(:open).and_yield(temp_file)
    allow(File).to receive(:read)
    allow(JSON).to receive(:parse)
    allow(Driver).to receive(:get_driver_dir).and_return('/data/local')
    Driver.new(device_id)
  end
  let(:driver_stub) { 'export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.oracle.Driver' }

  describe '#make_target' do
    let(:device_id) { '' }
    let(:make_target) { driver.make_target(class_name, method_signature, *args) }

    subject { make_target }
    it { should eq batch_item }
  end

  describe '#run_batch' do
    let(:device_id) { '' }
    let(:batch) { [batch_item] }
    let(:run_batch) { driver.run_batch(batch) }

    subject { run_batch }
    it do
      expect(temp_file).to receive(:<<).with(batch.to_json).ordered
      expect(driver).to receive(:adb).with("push #{temp_file.path} /data/local/od-targets.json")
      expect(driver).to receive(:drive).with("#{driver_stub} @/data/local/od-targets.json", true)
      allow(JSON).to receive(:parse) { {} }
      expect(driver).to receive(:adb).with("pull /data/local/od-output.json #{temp_file.path}")
      expect(driver).to receive(:adb).with('shell rm /data/local/od-output.json')
      subject
    end
  end

  describe '#run' do
    context 'with a device id' do
      let(:device_id) { '1234abcd' }

      context 'with integer arguments' do
        subject { driver.run(class_name, method_signature, *args) }
        it do
          allow(driver).to receive(:drive)
          expect(driver).to receive(:drive).with("#{driver_stub} 'some.Klazz' 'run' I:1 I:2 I:3")
          subject
        end
      end
    end

    context 'without a device id' do
      let(:device_id) { '' }

      context 'with string argument' do
        let(:class_name) { 'string/Klazz' }
        let(:method_signature) { 'run(Ljava/lang/String;)V' }
        let(:args) { 'hello string' }

        subject { driver.run(class_name, method_signature, args) }
        it do
          allow(driver).to receive(:drive)
          expect(driver).to receive(:drive).with(
            "#{driver_stub} 'string.Klazz' 'run' java.lang.String:[104,101,108,108,111,32,115,116,114,105,110,103]"
          )
          subject
        end
      end
    end
  end
end
