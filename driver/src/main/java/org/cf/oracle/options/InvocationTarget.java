package org.cf.oracle.options;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Method;

public class InvocationTarget {

    private final String id;
    private final String className;
    private final String methodName;
    private final String[] argumentStrings;

    private Object[] arguments;
    private Method method;
    private Throwable parseException = null;

    InvocationTarget(String id, String className, String methodName, String[] argumentStrings) {
        this.id = id;
        this.className = className;
        this.methodName = methodName;
        this.argumentStrings = argumentStrings;
    }

    public String toString() {
        StringBuilder sb = new StringBuilder("InvocationTarget{")
                .append("class=")
                .append(className).append("; method=")
                .append(methodName).append("; args=");

        for (String argumentString : argumentStrings) {
            sb.append('\'').append(argumentString).append("',");
        }
        if (argumentStrings.length > 0) {
            sb.setLength(sb.length() - 1);
        }

        if (getParseException() != null) {
            sb.append("; EXCEPTION=");
            StringWriter sw = new StringWriter();
            getParseException().printStackTrace(new PrintWriter(sw));
            sb.append(sw.getBuffer());

        }

        sb.append('}');

        return sb.toString();
    }

    public void setArguments(Object... arguments) {
        this.arguments = arguments;
    }

    public Object[] getArguments() {
        return arguments;
    }

    public String[] getArgumentStrings() {
        return this.argumentStrings;
    }

    public String getId() {
        return id;
    }

    public Method getMethod() {
        return method;
    }

    public String getClassName() {
        return className;
    }

    public String getMethodName() {
        return methodName;
    }

    public void setMethod(Method method) {
        this.method = method;
    }

    public Throwable getParseException() {
        return this.parseException;
    }

    public void setParseException(Throwable parseException) {
        this.parseException = parseException;
    }

}
