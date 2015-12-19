.class public Lorg/cf/BytesDecrypt;
.super Ljava/lang/Object;

.method public static doStuff()V
    .locals 1

    const-string v0, "asdf"

    invoke-virtual {v0}, Ljava/lang/String;->getBytes()[B

    move-result-object v0

    invoke-static {v0}, Lorg/cf/BytesDecrypt;->decrypt([B)Ljava/lang/String;

    move-result-object v0

    return-void
.end method
