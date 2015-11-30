package org.cf.driver;

/*
 * TODO:
 * load parameters from file
 * batch processing
 * peek fields
 */

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;

public class OracleDriver {

    private static String ClassName;
    private static String MethodName;
    private static Class<?>[] ParamTypes;
    private static Object[] ParamList;
    private static Gson gson = new GsonBuilder().disableHtmlEscaping().create();

    public static void main(String[] argv) throws Exception {
        if (argv.length < 2) {
            showUsage();
            System.exit(-1);
        }

        parseParameters(argv);

        Class<?> methodClass = null;
        try {
            methodClass = Class.forName(ClassName);
        } catch (ClassNotFoundException ex) {
            die("Parent class: " + ClassName + " does not to exist. Check Class.forName() formatting.");
        }

        // System.out.println("Method types: " + Arrays.deepToString(ParamTypes));
        Method m = null;
        try {
            m = methodClass.getDeclaredMethod(MethodName, ParamTypes);
        } catch (NoSuchMethodException ex) {
            String params = Arrays.deepToString(ParamTypes);
            die("Method: " + ClassName + "." + MethodName + "(" + params + ") does not appear to exist. Check method signature.");
        }
        Class<?> returnClass = m.getReturnType();

        // Private method? No problem.
        m.setAccessible(true);

        // Setup Lies for stack trace
        setupStackTraceSpoof();

        Object returnObject = null;
        try {
            returnObject = m.invoke(null, ParamList);
        } catch (IllegalAccessException ex) {
            die("I don't have access to invoke that method.\nException: " + ex);
        } catch (InvocationTargetException ex) {
            die("The invoked method caused an exception:\n" + ex);
        }

        // I hear an ancient voice, whispering from the Void, and it chills my lightless heart...
        if (returnClass.getName().equals("Ljava.lang.Void;")) {
            return;
        }

        // Lazy hack, if casting fails just let gson do it
        String output = "";
        try {
            output = gson.toJson(returnClass.cast(returnObject));
        } catch (Exception ex) {
            output = gson.toJson(returnObject);
        }

        System.out.println(output);
    }

    private static void parseParameters(String[] params) throws Exception {
        ClassName = params[0];
        MethodName = params[1];
        ParamTypes = new Class[params.length - 2];
        ParamList = new Object[ParamTypes.length];
        for (int i = 0; i < ParamTypes.length; i++) {
            String[] parts = params[i + 2].split(":", 2);
            String className = parts[0];

            // Non-array primitive types wont work with Class.forName()
            if (className.equals("I")) {
                ParamTypes[i] = int.class;
            } else if (className.equals("V")) {
                ParamTypes[i] = void.class;
            } else if (className.equals("Z")) {
                ParamTypes[i] = boolean.class;
            } else if (className.equals("B")) {
                ParamTypes[i] = byte.class;
            } else if (className.equals("S")) {
                ParamTypes[i] = short.class;
            } else if (className.equals("J")) {
                ParamTypes[i] = long.class;
            } else if (className.equals("C")) {
                ParamTypes[i] = char.class;
            } else if (className.equals("F")) {
                ParamTypes[i] = float.class;
            } else if (className.equals("D")) {
                ParamTypes[i] = double.class;
            } else {
                // Primitive arrays and everything else will, though.
                try {
                    ParamTypes[i] = Class.forName(className);
                } catch (ClassNotFoundException ex) {
                    die("Parameter class: " + className + " does not to exist. Check Class.forName() formatting.");
                }
            }

            if (parts.length > 1) {
                String itemJson = parts[1];

                if (ParamTypes[i] == String.class) {
                    try {
                        /*
                         * Strings are normalized to byte array format to avoid escaping
                         * 4 different layers: ruby, bash, adb's shell and java
                         */
                        byte[] safe = (byte[]) gson.fromJson(itemJson, Class.forName("[B"));
                        ParamList[i] = new String(safe);
                        System.out.println("i=" + i + ", " + ParamList[i]);
                    } catch (JsonSyntaxException ex) {
                        /*
                         * Maybe they're not using a byte array format for the string?
                         * GOOD LUCK.
                         */
                        ParamList[i] = itemJson;
                    }
                } else {

                    // System.out.println("Parsing: " + itemJson + " as " + ParamTypes[i]);
                    ParamList[i] = gson.fromJson(itemJson, ParamTypes[i]);
                }
            } else {
                ParamList[i] = null;
            }

        }
    }

    private static void setupStackTraceSpoof() throws Exception {
        /*
         * If stackspoof.cfg in current directory, read in.
         * String declaringClass, String methodName, String fileName, int lineNumber
         */
        File f = new File("/data/local/stackspoof.cfg");
        if (!f.exists()) {
            return;
        }

        BufferedReader in = new BufferedReader(new FileReader(f));
        while (in.ready()) {
            String s = in.readLine();
            String[] params = s.split(" ");
            StackTraceSpoofer.main(params);
        }
        in.close();
    }

    private static void showUsage() {
        System.out.println("Usage: dvz -classpath /data/local/driver.zip OracleDriver <class> <method> [<parameter type>:<parameter value json>]");
    }

    private static void die(String msg) {
        System.err.println(msg);
        System.exit(-1);
    }

}
