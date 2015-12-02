package org.cf.oracle.options;

import java.lang.reflect.Method;

public class InvocationTarget {

    private Object[] arguments;
    private Method method;

    void setArguments(Object[] arguments) {
        this.arguments = arguments;
    }

    void setMethod(Method method) {
        this.method = method;
    }

    public Object[] getArguments() {
        return arguments;
    }

    public Method getMethod() {
        return method;
    }

}
