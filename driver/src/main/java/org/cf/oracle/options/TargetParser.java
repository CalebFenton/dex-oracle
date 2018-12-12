package org.cf.oracle.options;

import com.google.gson.*;
import org.cf.oracle.FileUtils;

import java.io.IOException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class TargetParser {

    private static void parseTarget(Gson gson, String className, String methodName, String... args) {
        InvocationTarget target = new InvocationTarget("none", className, methodName, args);
        parseTargetExceptionally(gson, target);
    }

    private static void parseTargetExceptionally(Gson gson, InvocationTarget target) {
        try {
            parseTarget(gson, target);
        } catch (ClassNotFoundException | NoSuchMethodException | ExceptionInInitializerError e) {
            target.setParseException(e);
        }
    }

    private static void parseTarget(Gson gson, InvocationTarget target) throws ClassNotFoundException, NoSuchMethodException {
        String[] args = target.getArgumentStrings();
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
                        byte[] stringBytes = gson.fromJson(jsonValue, byte[].class);
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
        target.setArguments(methodArguments);

        Class<?> methodClass = Class.forName(target.getClassName());
        Method method = methodClass.getDeclaredMethod(target.getMethodName(), parameterTypes);
        target.setMethod(method);
    }

    private static List<InvocationTarget> loadTargetsFromFile(Gson gson, String fileName) throws IOException {
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

            InvocationTarget target = new InvocationTarget(id, className, methodName, arguments);
            parseTargetExceptionally(gson, target);
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
            return Class.forName(className);
        }
    }

    public static List<InvocationTarget> parse(String[] args, Gson gson) throws IOException {
        if (args[0].startsWith("@")) {
            String fileName = args[0].substring(1);

            return loadTargetsFromFile(gson, fileName);
        } else {
            String className = args[0];
            String methodName = args[1];
            String[] argumentStrings = Arrays.copyOfRange(args, 2, args.length);
            InvocationTarget target = new InvocationTarget("none", className, methodName, args);
            parseTargetExceptionally(gson, target);

            List<InvocationTarget> targets = new LinkedList<InvocationTarget>();
            targets.add(target);

            return targets;
        }
    }

}
