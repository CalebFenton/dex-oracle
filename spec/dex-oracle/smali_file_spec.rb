require 'spec_helper'

describe SmaliFile do
    let(:data_path) { 'spec/data/smali' }

    context 'the hello world smali' do
        let(:file_path) { "#{data_path}/helloworld.smali" }
        let(:smali_file) { SmaliFile.new(file_path) }
        let(:method_body) { <<-EOF

    .locals 2

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "hello,world!"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V

    return-void
        EOF
        }

        subject { smali_file }
        its(:class) { should eq 'LHelloWorld;' }
        its(:super) { should eq 'Ljava/lang/Object;' }
        its(:interfaces) { should eq ["Lsome/Interface1;", "Lsome/Interface2;"] }
        its(:fields) { should eq [SmaliField.new('LHelloWorld;', 'someField:Z')] }
        its(:methods) {
            should eq [SmaliMethod.new('LHelloWorld;', 'main([Ljava/lang/String;)V', method_body)]
        }

        describe '#update' do
            subject { smali_file.content }
            it 'should update modified methods' do
                method = smali_file.methods.first
                method.modified = true
                method.body = "\nreturn-void\n"
                smali_file.update
                should eq ".class public LHelloWorld; # COMMENT;\n.super Ljava/lang/Object; # YEAH ;\n.implements Lsome/Interface1;\n.implements Lsome/Interface2;\n\n.field public static final someField:Z\n\n.method public static main([Ljava/lang/String;)V\nreturn-void\n.end method\n\n"
            end
        end
    end
end
