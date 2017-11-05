package org.cf.oracle;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

public class FileUtils {

    public static String readFile(String fileName) throws IOException {
        FileInputStream fis = new FileInputStream(fileName);
        BufferedReader in = new BufferedReader(new InputStreamReader(fis, "UTF-8"));

        StringBuilder sb = new StringBuilder();
        while (in.ready()) {
            String line = in.readLine();
            sb.append(line).append('\n');
        }
        in.close();
        fis.close();

        return sb.toString();
    }

    public static void writeFile(String fileName, String contents) throws FileNotFoundException,
                    UnsupportedEncodingException {
        PrintWriter out = new PrintWriter(fileName, "UTF-8");
        out.write(contents);
        out.close();
    }

}
