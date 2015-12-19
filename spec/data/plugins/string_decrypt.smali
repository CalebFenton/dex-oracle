.class public Lorg/cf/StringDecrypt;
.super Ljava/lang/Object;

.method public static doStuff()V
    .locals 1

    const-string v0, "encrypted"

    invoke-static {v0}, Lorg/cf/StringDecrypt;->decrypt(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-void
.end method

