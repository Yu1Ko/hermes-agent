import importlib,os,sys

importlib.invalidate_caches()
module_path = os.getcwd()
module_path = os.path.join(module_path, "UAutoProfilerTool")

print(module_path)
sys.path.append(module_path)
module = importlib.import_module('Profile_test')

sys.path.remove(module_path)
print(module)