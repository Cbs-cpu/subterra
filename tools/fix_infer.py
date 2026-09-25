import re, subprocess, sys
G = "C:/Users/Cobos/Desktop/Godot_v4.6.3-stable_win64_console.exe"
for it in range(30):
    out = subprocess.run([G, "--headless", "--path", ".", "-s", "res://tools/check.gd"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=200).stdout
    lines = out.splitlines()
    fixed = 0
    for i, l in enumerate(lines):
        m = re.search(r'Cannot infer the type of "(\w+)"', l)
        if m and i + 1 < len(lines):
            m2 = re.search(r'\(res://(.+?):(\d+)\)', lines[i + 1])
            if not m2: continue
            path, ln = m2.group(1), int(m2.group(2))
            src = open(path, encoding="utf-8").read().split("\n")
            old = src[ln - 1]
            new = re.sub(r'\b(var|for) %s :=' % m.group(1), r'\1 %s =' % m.group(1), old, count=1)
            if new != old:
                src[ln - 1] = new
                open(path, "w", encoding="utf-8").write("\n".join(src))
                fixed += 1
    others = [l for l in lines if "SCRIPT ERROR" in l and "Cannot infer" not in l]
    print("iter", it, "fixed", fixed)
    if fixed == 0:
        print("\n".join(l for l in lines if "SCRIPT ERROR" in l or "at: GDScript" in l or "FALLA" in l or "revisados" in l))
        break
