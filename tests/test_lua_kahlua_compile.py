import os
import subprocess
import tempfile
import unittest

PZ_DIR = r"H:\SteamLibrary\steamapps\common\ProjectZomboid"
JAVA_EXE = os.path.join(PZ_DIR, "jre64", "bin", "java.exe")
PZ_JAR = os.path.join(PZ_DIR, "projectzomboid.jar")
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

class TestLuaKahluaCompile(unittest.TestCase):
    def test_kahlua_compile_all_lua_files(self):
        """Verify that all Lua files in the repository compile cleanly with PZ's Kahlua VM without exceeding upvalue or syntax limits."""
        lua_files = []
        for root, _, files in os.walk(REPO_ROOT):
            if ".git" in root or "node_modules" in root:
                continue
            for f in files:
                if f.endswith(".lua"):
                    lua_files.append(os.path.join(root, f))

        self.assertTrue(len(lua_files) > 0, "No Lua files found to test")

        if os.path.isfile(JAVA_EXE) and os.path.isfile(PZ_JAR):
            with tempfile.TemporaryDirectory() as scratch_dir:
                java_src = os.path.join(scratch_dir, "KahluaCompileCheck.java")
                with open(java_src, "w", encoding="utf-8") as f:
                    f.write("""import java.io.FileInputStream;
import java.io.InputStream;
import java.lang.reflect.Method;

public class KahluaCompileCheck {
    public static void main(String[] args) {
        try {
            Class<?> compilerClass = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler");
            Class<?> tableClass = Class.forName("se.krka.kahlua.vm.KahluaTable");
            Method loadis = compilerClass.getMethod("loadis", InputStream.class, String.class, tableClass);
            for (String file : args) {
                try (FileInputStream is = new FileInputStream(file)) {
                    loadis.invoke(null, is, file, null);
                    System.out.println("PASS: " + file);
                } catch (java.lang.reflect.InvocationTargetException ite) {
                    System.err.println("FAIL: " + file);
                    ite.getCause().printStackTrace(System.err);
                    System.exit(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(2);
        }
    }
}
""")
                javac_path = "javac"
                if os.path.isfile(r"C:\Program Files\Java\jdk-17\bin\javac.exe"):
                    javac_path = r"C:\Program Files\Java\jdk-17\bin\javac.exe"
                comp_res = subprocess.run([javac_path, java_src], capture_output=True, text=True)
                if comp_res.returncode != 0:
                    self.skipTest(f"Could not compile java helper: {comp_res.stderr}")

                cmd = [JAVA_EXE, "-cp", f"{PZ_JAR};{scratch_dir}", "KahluaCompileCheck"] + lua_files
                res = subprocess.run(cmd, capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, f"Kahlua compilation failed:\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
        else:
            self.skipTest("Project Zomboid installation not detected on this machine")

if __name__ == "__main__":
    unittest.main()
