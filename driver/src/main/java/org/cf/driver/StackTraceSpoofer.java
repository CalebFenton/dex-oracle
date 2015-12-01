package org.cf.driver;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.LinkedList;
import java.util.List;

public class StackTraceSpoofer {

    private static List<StackTraceElement> stack = new LinkedList<StackTraceElement>();

    private static void addElement(String declaringClass, String methodName, String fileName, int lineNumber) {
        stack.add(new StackTraceElement(declaringClass, methodName, fileName, lineNumber));
    }

    static void init() throws Exception {
        // <declaring class> <method name> <filename> <line number>
        File f = new File("stackspoof.cfg");
        if (!f.exists()) {
            return;
        }

        BufferedReader in = new BufferedReader(new FileReader(f));
        while (in.ready()) {
            String s = in.readLine();
            String[] params = s.split(" ");
            addElement(params[0], params[1], params[2], Integer.parseInt(params[3]));
        }
        in.close();
    }

    public static StackTraceElement[] getStackTrace() {
        return stack.toArray(new StackTraceElement[stack.size()]);
    }

}
