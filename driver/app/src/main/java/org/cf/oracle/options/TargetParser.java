package org.cf.oracle.options;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

import org.cf.oracle.FileUtils;

import java.io.IOException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import dalvik.system.DexClassLoader;

public class TargetParser {

    private static DexClassLoader appClassLoader;

    private static InvocationTarget buildTarget(Gson gson, String className, String methodName, String... args)
                    throws ClassNotFoundException, NoSuchMethodException, SecurityException {
        return buildTarget(gson, "", className, methodName, args);
    }

    private static InvocationTarget buildTarget(Gson gson, String id, String className, String methodName,
                    String... args) throws ClassNotFoundException, NoSuchMethodException, SecurityException {
        Class<?>[] parameterTypes = new Class[args.length];
        Object[] methodArguments = new Object[parameterTypes.length];
        for (int i = 0; i < parameterTypes.length; i++) {
            String[] parts = args[i].split(":", 2);
            parameterTypes[i] = smaliToJavaClass(parts[0]);
            if (parts.length == 1) {
                methodArguments[i] = null;
            } else {
                String jsonValue = parts[1];
                if (parameterTypes[i] == String.class) {
                    try {
                        // Normalizing strings to byte[] avoids escaping ruby, bash, adb shell, and java
                        byte[] stringBytes = (byte[]) gson.fromJson(jsonValue, appClassLoader.loadClass("[B"));
                        methodArguments[i] = new String(stringBytes);
                    } catch (JsonSyntaxException ex) {
                        // Possibly not using byte array format for string (good luck)
                        methodArguments[i] = jsonValue;
                    }
                } else {
                    // System.out.println("Parsing: " + itemJson + " as " + paramTypes[i]);
                    methodArguments[i] = gson.fromJson(jsonValue, parameterTypes[i]);
                }
            }
        }

        Class<?> methodClass = appClassLoader.loadClass(className);
        Method method = methodClass.getDeclaredMethod(methodName, parameterTypes);

        return new InvocationTarget(id, args, methodArguments, method);
    }

    private static List<InvocationTarget> loadTargetsFromFile(Gson gson, String fileName) throws IOException,
                    ClassNotFoundException, NoSuchMethodException, SecurityException {
        String targetJson = FileUtils.readFile(fileName);
        JsonArray targetItems = new JsonParser().parse(targetJson).getAsJsonArray();
        // JsonArray targetItems = json.getAsJsonArray();
        List<InvocationTarget> targets = new LinkedList<InvocationTarget>();
        for (JsonElement element : targetItems) {
            JsonObject targetItem = element.getAsJsonObject();
            String id = targetItem.get("id").getAsString();
            String className = targetItem.get("className").getAsString();
            String methodName = targetItem.get("methodName").getAsString();
            JsonArray argumentsJson = targetItem.get("arguments").getAsJsonArray();
            String[] arguments = new String[argumentsJson.size()];
            for (int i = 0; i < arguments.length; i++) {
                arguments[i] = argumentsJson.get(i).getAsString();
            }

            InvocationTarget target = buildTarget(gson, id, className, methodName, arguments);
            targets.add(target);
        }

        return targets;
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
            return appClassLoader.loadClass(className);
        }
    }

    public static List<InvocationTarget> parse(String[] args, Gson gson) throws ClassNotFoundException,
                    NoSuchMethodException, SecurityException, IOException {
        appClassLoader = new DexClassLoader("app.zip", ".", ".", ClassLoader.getSystemClassLoader());
        if (args[0].startsWith("@")) {
            String fileName = args[0].substring(1);

            return loadTargetsFromFile(gson, fileName);
        } else {
            InvocationTarget target = buildTarget(gson, args[0], args[1], Arrays.copyOfRange(args, 2, args.length));
            List<InvocationTarget> targets = new LinkedList<InvocationTarget>();
            targets.add(target);

            return targets;
        }
    }

}
