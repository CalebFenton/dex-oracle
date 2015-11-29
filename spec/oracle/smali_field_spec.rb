require 'spec_helper'

describe SmaliField do
    context 'with simple field' do
        let(:class_name) { 'Lorg/cfg/MyClass;' }
        let(:field_signature) { 'someField:Ljava/lang/Object;' }
        let(:smali_field) { SmaliField.new(class_name, field_signature) }
        subject { smali_field }

        its(:class) { should eq class_name }
        its(:name) { should eq 'someField' }
        its(:type) { should eq 'Ljava/lang/Object;' }
        its(:descriptor) { should eq "#{class_name}->#{field_signature}" }
    end
end
