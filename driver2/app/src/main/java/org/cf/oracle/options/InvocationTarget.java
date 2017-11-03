package org.cf.oracle.options;

import java.lang.reflect.Method;

public class InvocationTarget {

    private final Object[] arguments;
    private final String[] argumentStrings;
    private final String id;
    private final Method method;

    InvocationTarget(String id, String[] argumentStrings, Object[] arguments, Method method) {
        this.id = id;
        this.argumentStrings = argumentStrings;
        this.arguments = arguments;
        this.method = method;
    }

    public Object[] getArguments() {
        return arguments;
    }

    public String getArgumentsString() {
        StringBuilder sb = new StringBuilder();
        for (String argumentString : argumentStrings) {
            sb.append('\'').append(argumentString).append("' ");
        }

        return sb.toString().trim();
    }

    public String getId() {
        return id;
    }

    public Method getMethod() {
        return method;
    }

}
