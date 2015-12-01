package org.cf.driver;

/*
 * TODO:
 * load parameters from file
 * batch processing
 * peek fields
 */

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;

public class OracleDriver {

    private static String ClassName;
    private static Gson gson = new GsonBuilder().disableHtmlEscaping().create();
    private static String MethodName;
    private static Class<?>[] ParameterTypes;
    private static Object[] ParameterValues;

    private static void die(String msg) {
        System.err.println(msg);
        System.exit(-1);
    }

    private static void parseParameters(String[] params) throws Exception {
        if (params.length < 2) {
            showUsage();
            System.exit(-1);
        }

        ClassName = params[0];
        MethodName = params[1];
        ParameterTypes = new Class[params.length - 2];
        ParameterValues = new Object[ParameterTypes.length];
        for (int i = 0; i < ParameterTypes.length; i++) {
            String[] parts = params[i + 2].split(":", 2);
            String className = parts[0];
            try {
                ParameterTypes[i] = smaliToJavaClass(className);
            } catch (ClassNotFoundException ex) {
                die("Parameter class: " + className + " does not to exist. Check Class.forName() formatting.");
            }

            if (parts.length == 1) {
                ParameterValues[i] = null;
            } else {
                String jsonValue = parts[1];
                if (ParameterTypes[i] == String.class) {
                    try {
                        /*
                         * Strings are normalized to byte array format to avoid escaping
                         * 4 different layers: ruby, bash, adb's shell and java
                         */
                        byte[] stringBytes = (byte[]) gson.fromJson(jsonValue, Class.forName("[B"));
                        ParameterValues[i] = new String(stringBytes);
                        // System.out.println("i=" + i + ", " + ParameterValues[i]);
                    } catch (JsonSyntaxException ex) {
                        // Possibly not using byte array format for string (bad idea)
                        ParameterValues[i] = jsonValue;
                    }
                } else {
                    // System.out.println("Parsing: " + itemJson + " as " + ParamTypes[i]);
                    ParameterValues[i] = gson.fromJson(jsonValue, ParameterTypes[i]);
                }
            }
        }
    }

    private static void showUsage() {
        System.out.println("Usage: dvz -classpath /data/local/od.zip org.cf.driver.OracleDriver <class> <method> [<parameter type>:<parameter value json>]");
    }

    private static Class<?> smaliToJavaClass(String className) throws ClassNotFoundException {
        if (className.equals("I")) {
            return int.class;
        } else if (className.equals("V")) {
            return void.class;
        } else if (className.equals("Z")) {
            return boolean.class;
        } else if (className.equals("B")) {
            return byte.class;
        } else if (className.equals("S")) {
            return short.class;
        } else if (className.equals("J")) {
            return long.class;
        } else if (className.equals("C")) {
            return char.class;
        } else if (className.equals("F")) {
            return float.class;
        } else if (className.equals("D")) {
            return double.class;
        } else {
            return Class.forName(className);
        }
    }

    public static void main(String[] argv) throws Exception {
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
            m = methodClass.getDeclaredMethod(MethodName, ParameterTypes);
        } catch (NoSuchMethodException ex) {
            String params = Arrays.deepToString(ParameterTypes);
            params = params.substring(1, params.length() - 1);
            die("Method: " + ClassName + "." + MethodName + "(" + params + ") does not appear to exist. Check method signature.");
        }

        StackTraceSpoofer.init();

        Class<?> returnClass = m.getReturnType();
        m.setAccessible(true);
        Object returnObject = null;
        try {
            returnObject = m.invoke(null, ParameterValues);
        } catch (IllegalAccessException ex) {
            die("I don't have access to invoke that method.\nException: " + ex);
        } catch (InvocationTargetException ex) {
            die("The invoked method caused an exception:\n" + ex);
        }

        // I hear an ancient voice, whispering from the Void, and it chills my lightless heart...
        if (returnClass.getName().equals("Ljava.lang.Void;")) {
            return;
        }

        // If casting fails, let gson do it.
        String output = "";
        try {
            output = gson.toJson(returnClass.cast(returnObject));
        } catch (Exception ex) {
            output = gson.toJson(returnObject);
        }

        System.out.println(output);
    }

}
