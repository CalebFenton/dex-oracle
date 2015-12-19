require 'spec_helper'

describe SmaliMethod do
  context 'with simple method' do
    let(:class_name) { 'Lorg/cfg/MyClass;' }
    let(:method_signature) { 'someMethod1(ILjava/lang/Object;J)Z' }
    let(:method_body) { ".locals 1\nconst/4 v0, 0x0\nreturn v0\n" }
    let(:smali_method) { SmaliMethod.new(class_name, method_signature, method_body) }
    subject { smali_method }

    its(:class) { should eq class_name }
    its(:name) { should eq 'someMethod1' }
    its(:descriptor) { should eq "#{class_name}->#{method_signature}" }
    its(:return_type) { should eq 'Z' }
    its(:parameters) { should eq ['I', 'Ljava/lang/Object;', 'J'] }
    its(:body) { should eq method_body }
    its(:modified) { should eq false }
  end
end
