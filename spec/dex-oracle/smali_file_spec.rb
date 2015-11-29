require 'spec_helper'

describe SmaliFile do
    DATA_PATH = 'spec/data/%s'

    context 'the hello world smali' do
        let(:file_path) { DATA_PATH % 'helloworld.smali' }
        let(:smali_file) { SmaliFile.new(file_path) }
        subject { smali_file }

        its(:class) { should eq 'LHelloWorld;' }
        its(:super) { should eq 'Ljava/lang/Object;' }
        its(:interfaces) { should eq ["Lsome/Interface1;", "Lsome/Interface2;"] }
        its(:fields) { should eq [SmaliField.new('LHelloWorld;', 'someField:Z')] }
        its(:methods) { should eq [SmaliMethod.new('LHelloWorld;', 'main([Ljava/lang/String;)V')] }
    end
end
