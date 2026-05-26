from u3driver import AltrunUnityDriver
from u3driver import By
import time

def AutoRun(udriver):
	try:
		time.sleep(2.269838)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIBaseSkillPad_H//Content//Battle//SkillButtons//AutoFight//Auto").tap()
		time.sleep(1.56945)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIJoystick_H//root").tap()
		time.sleep(33.98669)
		udriver.find_object(By.PATH,"//Main//UIMgr").tap()
		time.sleep(1.034378)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIMainRoot//UIBaseHead_H//Player//Touxiang//Touxiang01").tap()
		time.sleep(1.33506)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIEquipmentAttribute_H//Shuxing//Xiangqing1//Neirong//Table//Title2//Item6//wenben_Button").tap()
		time.sleep(0.7678452)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIEquipment_H//Anniu_Fanhui").tap()
		time.sleep(0.7704468)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIBaseSkillPad_H//Content//Battle//SkillButtons//Target//Auto").tap()
		time.sleep(0.982399)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIBaseSkillPad_H//Content//Battle//SkillButtons//Target//Auto").tap()
		time.sleep(0.4340057)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIMainRoot//UIBaseEntry1_H//Anchors//Content//Btn_Switch").tap()
		time.sleep(1.00119)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIMainRoot//UIBaseEntry1_H//Anchors//Content//Tip//Grid3//Shezhi").tap()
		time.sleep(1.987335)
		udriver.find_object(By.PATH,"//Main//UIMgr//UISystemSetup_H//Anchors//Content//JichuShezhi//Picture//Content//Btn_Out").tap()
		time.sleep(4.273331)
		udriver.find_object(By.PATH,"//Main//UIMgr//UIPopPanel_C//Content//Type2//Btn2").tap()
