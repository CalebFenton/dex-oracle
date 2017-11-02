package org.cf.oracle;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.lang.Class;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class ClassNameUtils {

    private static final Map<String, String> internalPrimitiveToBinaryName;
    private static final Map<String, String> binaryNameToInternalPrimitive;

    static {
        internalPrimitiveToBinaryName = new HashMap<>();
        internalPrimitiveToBinaryName.put("I", int.class.getName());
        internalPrimitiveToBinaryName.put("S", short.class.getName());
        internalPrimitiveToBinaryName.put("J", long.class.getName());
        internalPrimitiveToBinaryName.put("B", byte.class.getName());
        internalPrimitiveToBinaryName.put("D", double.class.getName());
        internalPrimitiveToBinaryName.put("F", float.class.getName());
        internalPrimitiveToBinaryName.put("Z", boolean.class.getName());
        internalPrimitiveToBinaryName.put("C", char.class.getName());
        internalPrimitiveToBinaryName.put("V", void.class.getName());

        binaryNameToInternalPrimitive = new HashMap<>();
        binaryNameToInternalPrimitive.put(int.class.getName(), "I");
        binaryNameToInternalPrimitive.put(short.class.getName(), "S");
        binaryNameToInternalPrimitive.put(long.class.getName(), "J");
        binaryNameToInternalPrimitive.put(byte.class.getName(), "B");
        binaryNameToInternalPrimitive.put(double.class.getName(), "D");
        binaryNameToInternalPrimitive.put(float.class.getName(), "F");
        binaryNameToInternalPrimitive.put(boolean.class.getName(), "Z");
        binaryNameToInternalPrimitive.put(char.class.getName(), "C");
        binaryNameToInternalPrimitive.put(void.class.getName(), "V");
    }

    public static String toInternal(Class<?> klazz) {
        return binaryToInternal(klazz.getName());
    }

    public static String getComponentBase(String className) {
        return className.replace("[", "").replace("]", "");
    }

    public static int getDimensionCount(String className) {
        String baseClassName = className.replace("[", "");

        return className.length() - baseClassName.length();
    }

    public static String binaryToInternal(String binaryName) {
        String baseName = getComponentBase(binaryName);
        StringBuilder sb = new StringBuilder();
        int dimensionCount = getDimensionCount(binaryName);
        for (int i = 0; i < dimensionCount; i++) {
            sb.append('[');
        }

        String internalPrimitive = binaryNameToInternalPrimitive.get(baseName);
        if (internalPrimitive != null) {
            return sb.append(internalPrimitive).toString();
        }

        if (dimensionCount > 0 && internalPrimitiveToBinaryName.containsKey(baseName)) {
            return sb.append(baseName).toString();
        }

        if (baseName.endsWith(";")) {
            sb.append(baseName.replace('.', '/'));
        } else {
            sb.append('L').append(baseName.replace('.', '/')).append(';');
        }

        return sb.toString();
    }
}
