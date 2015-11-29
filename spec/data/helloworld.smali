.class public LHelloWorld; # COMMENT;
.super Ljava/lang/Object; # YEAH ;
.implements Lsome/Interface1;
.implements Lsome/Interface2;
 
.field public static final someField:Z

.method public static main([Ljava/lang/String;)V
    .locals 2

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream; 
    const-string v1, "hello,world!"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V

    return-void
.end method
