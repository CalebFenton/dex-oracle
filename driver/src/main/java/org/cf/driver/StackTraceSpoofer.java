package org.cf.driver;

public class StackTraceSpoofer {

    public static StackTraceElement[] stack = new StackTraceElement[2];

    public static void main(String[] argv) {
        if (argv[0].equals("root")) {
            setRootElement(argv[1], argv[2], argv[3], Integer.parseInt(argv[4]));
        } else if (argv[0].equals("first")) {
            setFirstElement(argv[1], argv[2], argv[3], Integer.parseInt(argv[4]));
        }
    }

    public static void setRootElement(String declaringClass, String methodName, String fileName, int lineNumber) {
        stack[0] = new StackTraceElement(declaringClass, methodName, fileName, lineNumber);
    }

    public static void setFirstElement(String declaringClass, String methodName, String fileName, int lineNumber) {
        stack[1] = new StackTraceElement(declaringClass, methodName, fileName, lineNumber);
    }

    public static StackTraceElement[] getStackTrace() {
        return stack;
    }

}
