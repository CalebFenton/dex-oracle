.class public Lorg/cf/MultiBytesDecrypt;
.super Ljava/lang/Object;

.method public static doStuff()V
    .locals 3

    const-string v0, "string1"

    new-instance v1, Ljava/lang/String;

    invoke-static {v0}, Lorg/cf/MultiBytesDecrypt;->doThing1(Ljava/lang/String;)[B

    move-result-object v2

    const-string v3, "string2"

    invoke-static {v2, v3}, Lorg/cf/MultiBytesDecrypt;->doThing2([BLjava/lang/String;)[B

    move-result-object v2

    invoke-static {v2}, Lorg/cf/MultiBytesDecrypt;->doThing3([B)[B

    move-result-object v2

    invoke-direct {v1, v2}, Ljava/lang/String;-><init>([B)V

    return-void
.end method
