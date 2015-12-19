.class public Lorg/cf/StringLookup;
.super Ljava/lang/Object;

.method public static doStuff()V
    .locals 3

    const/4 v0, 0x0

    const/4 v1, 0x1

    const/4 v2, 0x2

    invoke-static {v0, v1, v2}, Lorg/cf/StringLookup;->lookup(III)Ljava/lang/String;

    move-result-object v0

    return-void
.end method
