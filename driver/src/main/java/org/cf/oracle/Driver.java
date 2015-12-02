package org.cf.oracle;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import org.cf.oracle.options.InvocationTarget;
import org.cf.oracle.options.TargetParser;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class Driver {

    public static final String DRIVER_DIR = "/data/local";
    private static final String EXCEPTION_LOG = DRIVER_DIR + "/od-exception.txt";
    private static final String OUTPUT_FILE = DRIVER_DIR + "/od-output.json";
    private static final Gson GSON = new GsonBuilder().disableHtmlEscaping().create();

    private static void die(Exception exception) {
        PrintWriter writer;
        try {
            writer = new PrintWriter(EXCEPTION_LOG, "UTF-8");
        } catch (Exception e) {
            return;
        }
        writer.println(exception);
        StringWriter sw = new StringWriter();
        exception.printStackTrace(new PrintWriter(sw));
        writer.println(sw.toString());
        writer.close();

        // app_process, dalvikvm, and dvz don't propagate exit codes, so this doesn't matter
        System.exit(-1);
    }

    private static String invokeMethod(Method method, Object[] arguments) throws IOException, IllegalAccessException,
                    IllegalArgumentException, InvocationTargetException {
        method.setAccessible(true);
        Object returnObject = method.invoke(null, arguments);

        Class<?> returnClass = method.getReturnType();
        if (returnClass.getName().equals("Ljava.lang.Void;")) {
            // I hear an ancient voice, whispering from the Void, and it chills my lightless heart...
            return null;
        }

        String output = "";
        try {
            output = GSON.toJson(returnClass.cast(returnObject));
        } catch (Exception ex) {
            output = GSON.toJson(returnObject);
        }

        return output;
    }

    private static void showUsage() {
        System.out.println("Usage: export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.driver.OracleDriver <class> <method> [<parameter type>:<parameter value json>]");
        System.out.println("       export CLASSPATH=/data/local/od.zip; app_process /system/bin org.cf.driver.OracleDriver @<json file>");
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            showUsage();
            System.exit(-1);
        }

        String output = null;
        try {
            StackSpoofer.init();
            List<InvocationTarget> targets = TargetParser.parse(args, GSON);
            if (targets.size() == 1) {
                InvocationTarget target = targets.get(0);
                output = invokeMethod(target.getMethod(), target.getArguments());
                if (output != null) {
                    System.out.println(output);
                }
            } else {
                String[] outputs = new String[targets.size()];
                for (int i = 0; i < outputs.length; i++) {
                    InvocationTarget target = targets.get(i);
                    outputs[i] = invokeMethod(target.getMethod(), target.getArguments());
                }
                String json = GSON.toJson(outputs);
                FileUtils.writeFile(OUTPUT_FILE, json);
            }
        } catch (Exception e) {
            die(e);
        }
    }

}
