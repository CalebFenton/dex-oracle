.class public Lorg/cf/CLInit;
.super Ljava/lang/Object;

.method static constructor <clinit>()V
    .locals 1

    const-string v0, "encrypted"

    invoke-static {v0}, Lorg/cf/CLInit;->decrypt(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-void
.end method
