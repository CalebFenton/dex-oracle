.class public Lorg/cf/ClassForName;
.super Ljava/lang/Object;

.method public static doStuff()V
    .locals 1

    const-string v0, "android.content.Intent"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    return-void
.end method
