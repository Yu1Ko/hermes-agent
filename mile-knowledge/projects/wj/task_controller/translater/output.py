from u3driver import AltrunUnityDriver
from u3driver import By
import time

def AutoRun(udriver):
	try:
		time.sleep(4.96)
		udriver.find_object(By.PATH,"//ActionRecord(Clone)//Record//StartRecordButton").tap()
		print("-" * 10 + "all command succeed" + "-" * 10)
	except Exception as e:
		print(f"{e}")
		raise e

