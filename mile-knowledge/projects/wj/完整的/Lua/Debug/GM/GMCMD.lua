require("Lua/Debug/GM/EquipItem.lua")
require("Lua/Debug/GM/EquipItemConfig.lua")

GMTools_LoadLuaFile_Starttime = GetTickCount()
GMTools_LoadLuaFile_old_memory = collectgarbage("count") --获取加载完成时的内存信息

if _G.bClassic==nil then
    function IsClassic()
        local a,b,c,d = GetVersion()
        --a Sword3.VersionLineFullName
        --b Sword3.version
        --c Sword3.VersionLineName
        --d Sword3.versionex
        return c == "classic"
    end
    _G.bClassic = IsClassic()
--~ else
--~     Output("已有_G.bClassic!") --临时输出
end

if _G.CurLife == nil then
    if not _G.bClassic then
        _G.CurLife = "fCurrentLife64"
        _G.MaxLife = "fMaxLife64"
    else
        _G.CurLife = "nCurrentLife"
        _G.MaxLife = "nMaxLife"
    end
end

if _G.CurMana == nil then
    _G.CurMana = "nCurrentMana"
    _G.MaxMana = "nMaxMana"
end

function GMMgr.ReloadSkillSinceScriptChanged(skillID)
    assert(skillID)
    ReloadSkillSinceScriptChanged(skillID)
    SendGMCommand(string.format("ReloadSkillSinceScriptChanged(%s)", skillID))
end

tGMCMD = {
    {text = "[其他] /gm",              pattern = "[qt]/gm",     CMDType = "GM",      NeedParam = true,      CMD = ""},
    {text = "[其他] /cmd",              pattern = "[qt]/cmd",     CMDType = "Local",     NeedParam = true,    CMD = ""},
    {text = "[其他] 添加临时服务器",       pattern = "[qt]tjlsfwq",     CMDType = "Local",      NeedParam = true,      CMD = "AddTempServer('127.0.0.1', '临时')--开发环境的服务器列表才有效"},
    {text = "[其他] 录制角色轨迹",       pattern = "[qt]lzjsgj",     CMDType = "Local",      NeedParam = false,      CMD = "RecordPos()"},
    {text = "[其他] 禁用新手教学",         pattern = "[qt]jyxsjx",     CMDType = "Local",     NeedParam = true,    CMD = "TeachEvent.CloseAllTeach();TeachEvent.bEnabled=false --false禁用，true启用"},
    {text = "[调试] 表现调试工具开关",             pattern = "[ts]bxtsgjkg",     CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('toggle ui')"},
    {text = "[调试] 一键学习新流派技能",            pattern = "[ts]yjxsxlpjn",    CMDType = "GM",    NeedParam = false,        CMD = 'for i,j in pairs(GetSkillAutoLearnTable(32).SkillArray) do player.LearnSkillLevel(j.dwSkillID, j.dwSkillLevel, true) end'},
    {text = "[物品] 包里道具删除",                 pattern = "[wp]bldjsc",     CMDType = "Local",    NeedParam = false,     CMD = "DeleteAllItem()"},
    {text = "[物品] 获得无名剑金箍棒",             pattern = "[wp]hdwmjjgb",     CMDType = "GM",        NeedParam = false,     CMD = "player.AddItem(5,3666,1);player.AddItem(6,01)"},    --player.AddItem(5,5284,1)九天.逍遥
    {text = "[物品] 获得马匹背包",                 pattern = "[wp]hdmpbb",     CMDType = "GM",        NeedParam = false,     CMD = "for i=506,509 do player.AddItem(8,i) end;for i=1,4 do player.AddItem(8,45) end;"},
    {text = "[物品] 获得机关弩箭",                 pattern = "[wp]hdjgnj",     CMDType = "GM",        NeedParam = false,     CMD = "for i=1,5 do player.AddItem(6,4000);player.AddItem(6,4014); end;"},
    {text = "[物品] 获得弹丸",                     pattern = "[wp]hddw",         CMDType = "GM",        NeedParam = false,     CMD = "for i=1,2 do player.AddItem(6,115);player.AddItem(6,116); end;"},
    {text = "[物品] 获得门派基础武器",             pattern = "[wp]hdmpjcwq",     CMDType = "GM",        NeedParam = false,     CMD = "local tWeapon = {18629,366,730,614,4012,5684,484,5183,6693,730,256,9288,10959,14519};for i,j in ipairs(tWeapon) do if player.GetItemAmount(6,j)<1 then player.AddItem(6,j) end end"},
    {text = "[物品] 快速获得校服切换道具",         pattern = "[wp]kshdxfdj",     CMDType = "GM",        NeedParam = false,     CMD = "player.AddItem(5,32301);"},
    ------------------------------------------------------------------------------>
    {text = "[属性] 角色升到指定等级",             pattern = "[sx]jssdzddj",     CMDType = "Local",    NeedParam = true,     CMD = "PlayerLevelUpToNew(130)"},
    {text = "[属性] 跑图常用设置", 				pattern = "[sx]ptcysz", 	CMDType = "GM", 	NeedParam = false, 	CMD = "if player.nMoveState == MOVE_STATE.ON_DEATH then player.Revive() end;player.AddBuff(0,99,203,1,7200);player.AddBuff(0,99,1900,1,7200);player.AddBuff(0,99,106,1,7200);player.AddBuff(0,99,297,3,7200);player.AddBuff(0,99,8665,1,7200);player.nLifeReplenishExt=1000000;player.AddBuff(player.dwID, player.nLevel, 4136,1,7200, 0, 50);player.AddBuff(0,99,19506,1,7200,0,50);player.".._G.MaxLife.."=100000000;player.".._G.CurLife.."=player.".._G.MaxLife..";"},
    {text = "[属性] 复活自己",                     pattern = "[sx]fhzj",         CMDType = "GM",        NeedParam = false,     CMD = "player.Revive()"},
    {text = "[属性] 清除伤害反弹",                pattern = "[sx]qcshft",     CMDType = "GM",        NeedParam = false,     CMD = "player.nPhysicsReflection=0"},
    {text = "[属性] 伤害反弹设置",                pattern = "[sx]shftsz",     CMDType = "GM",        NeedParam = true,     CMD = "player.nPhysicsReflection=200000    --0就是不反弹"},
    {text = "[属性] 加强回血回蓝",                pattern = "[sx]jqhxhl",     CMDType = "GM",     NeedParam = true,     CMD = "player.nLifeReplenishExt=100000;player.nManaReplenishExt=100000"},
    {text = "[属性] 提高血量",                     pattern = "[sx]tgxl",         CMDType = "GM",        NeedParam = false,     CMD = "player.".._G.MaxLife.." = 9999999;player.".._G.CurLife.." = 9999999"},
    {text = "[属性] 提高内力",                     pattern = "[sx]tgnl",         CMDType = "GM",        NeedParam = false,     CMD = "player.nMaxMana = 9999999;player.nCurrentMana = 9999999"},
    {text = "[属性] 提高攻击",                     pattern = "[sx]tggj",         CMDType = "GM",        NeedParam = true,     CMD = "player.nPhysicsAttackPower=200000;player.nSolarAttackPower=200000;player.nNeutralAttackPower=200000;player.nLunarAttackPower=200000;player.nPoisonAttackPower=200000"},
    {text = "[属性] 添加活力",                    pattern = "[sx]tjhl",         CMDType = "GM",        NeedParam = true,     CMD = "player.AddVigor(100)"},
    {text = "[属性] 添加活力上限",                pattern = "[sx]tjhlsx",     CMDType = "GM",        NeedParam = true,     CMD = "player.AddVigorRemainSpace(1000)"},
--~     {text = "[属性] 精力全满",                    pattern = "[sx]jlqm",         CMDType = "GM",        NeedParam = false,     CMD = "player.nCurrentStamina = player.nMaxStamina"},
--~     {text = "[属性] 体力全满",                    pattern = "[sx]tlqm",         CMDType = "GM",        NeedParam = false,     CMD = "player.nCurrentThew = player.nMaxThew"},
    {text = "[属性] 增加经验金钱修为",             pattern = "[sx]zjjyjqxw",    CMDType = "GM",        NeedParam = true,     CMD = "player.AddExp(500000);player.AddMoney(10000,0,0);player.AddTrain(500000)"},
    {text = "[属性] 增加帮贡侠义威望",             pattern = "[sx]zjbgxyww",    CMDType = "GM",        NeedParam = true,     CMD = "player.AddContribution(111);player.AddJustice(111);player.AddPrestige(111)"},
    {text = "[属性] 增加监本印文数值",             pattern = "[sx]zjjbywsz",    CMDType = "GM",        NeedParam = false,     CMD = "player.AddExamPrintRemainSpace(3500);player.AddExamPrint(3500)"},
    {text = "[属性] 设置势力",                     pattern = "[sx]szsl",         CMDType = "GM",        NeedParam = true,     CMD = "player.SetForceID()"},
    {text = "[属性] 增加声望",                     pattern = "[sx]zjsw",         CMDType = "GM",        NeedParam = true,     CMD = "player.AddReputation(声望ID,声望值)"},
    {text = "[属性] 更换阵营",                    pattern = "[sx]ghzy",         CMDType = "GM",        NeedParam = true,     CMD = "player.SetCamp(1) -- 1 为浩气，2恶人，0为中立，要切换浩气或恶人，需要先回到中立"},
    {text = "[属性] 获得成就",                     pattern = "[sx]hdcj",         CMDType = "GM",     NeedParam = true,     CMD = "player.AcquireAchievement()"},
    {text = "[属性] 删除成就",                     pattern = "[sx]sccj",         CMDType = "GM",     NeedParam = true,     CMD = "player.RemoveAchievement()"},
    {text = "[属性] 设置别名目标变量值",        pattern = "[sx]szbmmbblz",     CMDType = "GM",     NeedParam = true,     CMD = "szName='';t=player.GetScene().GetNpcByNickName(szName);t.SetCustomInteger4(ID, 0)"},
    {text = "[属性] 设置选中目标变量值",         pattern = "[sx]szxzmbblz",     CMDType = "GM",     NeedParam = true,    CMD = "t=player.GetSelectCharacter();t.SetCustomInteger4(ID, 0)"},
    {text = "[属性] 获取选中目标变量值",         pattern = "[sx]hqxzmbblz",     CMDType = "GM",     NeedParam = true,    CMD = "t=player.GetSelectCharacter();player.SendSystemMessage(t.GetCustomInteger4(ID));"},
    ------------------------------------------------------------------------------>
    {text = "[BUFF] AP命中加成",                 pattern = "[buff]apmzjc",    CMDType = "GM",        NeedParam = true,     CMD = "for i=1,50 do player.AddBuff(player.dwID,player.nLevel,5235,1,1) end --1层10W AP，3%命中，可以叠加50层，时长是无限的"},
    {text = "[BUFF] 测试会心加成",                 pattern = "[buff]cshxjc",    CMDType = "GM",        NeedParam = true,     CMD = "for i=1,10 do player.AddBuff(player.dwID,player.nLevel,6731,1,1) end --1层10%会心，可以叠加10层，时长是无限的"},
    {text = "[BUFF] 超级血量",                     pattern = "[buff]cjxl",        CMDType = "GM",        NeedParam = false,     CMD = "for i=1,50 do player.AddBuff(0,99,4136,1,7200) end;player.".._G.CurLife.."=player.".._G.MaxLife},
    {text = "[BUFF] 无敌加速回血反弹",            pattern = "[buff]wdjshxft", CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,203,1,7200);player.AddBuff(0,99,1900,1,7200);player.AddBuff(0,99,8233,10,7200);player.AddBuff(0,99,297,3,7200);player.nLifeReplenishExt=9000000;player.nPhysicsReflection=1000000;"},
    {text = "[BUFF] 加速",                         pattern = "[buff]js",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,8233,10,7200)"},
    {text = "[BUFF] 隐身疾行",                     pattern = "[buff]ysjs",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,6008,1,7200)"},
    {text = "[BUFF] 隐身",                         pattern = "[buff]ys",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,108,1,7200)"},
    {text = "[BUFF] 切换隐身gm",                 pattern = "[buff]qhysgm",    CMDType = "GM",        NeedParam = true,     CMD = "local p=GetPlayer(6291899) or player;if p then if p.GetBuff(1459,1) then p.DelBuff(1459,1) else p.AddBuff(player.dwID,player.nLevel,1459,1,20) end end"},
    {text = "[BUFF] 不死",                         pattern = "[buff]bs",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,203,1,7200)"},
    {text = "[BUFF] 无敌",                         pattern = "[buff]wd",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,377,1,7200)"},
    {text = "[BUFF] 无限气力值",                 pattern = "[buff]wxqlz",    CMDType = "GM",        NeedParam = false,     CMD = "player.AddBuff(0,99,8665,1,7200)"},
    {text = "[BUFF] 取消无限气力值",             pattern = "[buff]qxwxqlz",    CMDType = "GM",        NeedParam = false,     CMD = "player.DelBuff(8665,1)"},
    {text = "[BUFF] 设置buff每跳间隔",             pattern = "[buff]szbuffmtjg",CMDType = "GM",    NeedParam = true,     CMD = "local p=player.GetSelectCharacter().GetBuff(10939,1) player.GetSelectCharacter().SetBuffNextActiveFrame(p.nIndex,111)"},
    ------------------------------------------------------------------------------>
    {text = "[目标] 设置目标血量",                pattern = "[mb]szmbxl",         CMDType = "GM",        NeedParam = true,     CMD = "n=player.GetSelectCharacter();n.".._G.CurLife.." = n.".._G.MaxLife.."*0.59"},
    {text = "[目标] 设置目标内力",                pattern = "[mb]szmbnl",         CMDType = "GM",        NeedParam = true,     CMD = "n=player.GetSelectCharacter();n.nCurrentMana = n.nMaxMana*0.59"},
    {text = "[目标] 添加目标BUFF(如加速隐身)",     pattern = "[mb]tjmbbuff",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().AddBuff(player.dwID,player.nLevel,106,1,36000)    --106加速,108隐身"},
    {text = "[目标] 删除目标BUFF(如加速隐身)",     pattern = "[mb]scmbbuff",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().DelBuff(106,1)    --106加速,108隐身"},
    {text = "[目标] 目标消失",                     pattern = "[mb]mbxs",        CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().SetDisappearFrames(1,0)"},
    {text = "[目标] 杀死目标",                    pattern = "[mb]ssmb",         CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().Die()"},
    {text = "[目标] 复活目标拉到脚下",             pattern = "[mb]fhmbldjx",     CMDType = "GM",        NeedParam = false,     CMD = "target = player.GetSelectCharacter(); target.Revive();target.SetPosition(player.nX,player.nY,player.nZ);"},
    {text = "[目标] 设置目标NPC脚本",            pattern = "[mb]szmbnpcjb",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().SetScript(\"脚本路径.lua\");ReloadAllScripts();"},
    {text = "[目标] 对目标发送AI事件",             pattern = "[mb]dmbfsaisj",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().FireAIEvent(2001, 0, 0)"},
    {text = "[目标] 对目标发送AI调试信息",         pattern = "[mb]dmbfsaitsxx",CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().SetAIDebug(1000)"},
    {text = "[目标] 清除目标仇恨",                 pattern = "[mb]qcmbch",        CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().ClearAllThreat()"},
    {text = "[目标] 禁止目标NPC对话",             pattern = "[mb]jzmbdh",        CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().SetDialogFlag(0)"},
    {text = "[目标] 允许目标NPC对话",             pattern = "[mb]yxmbdh",        CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().SetDialogFlag(1)"},
    {text = "[目标] 目标做动作",                pattern = "[mb]mbzdz",         CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().DoAction(0, 10056)"},
    {text = "[目标] 目标释放技能",                pattern = "[mb]mbsfjn",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().CastSkill(ID, 1)"},
    {text = "[目标] 目标遗忘技能",                pattern = "[mb]mbywjn",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().ForgetSkill(ID)"},
    {text = "[目标] 目标遗忘奇穴",                pattern = "[mb]mbywqx",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().ClearNewTalent()"},
    {text = "[目标] 目标走过来",                pattern = "[mb]mbzgl",         CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().WalkTo(player.nX,player.nY)"},
    {text = "[目标] 目标跑过来",                pattern = "[mb]mbpgl",         CMDType = "GM",        NeedParam = false,     CMD = "player.GetSelectCharacter().RunTo(player.nX,player.nY)"},
    {text = "[目标] 目标换模",                    pattern = "[mb]mbhm",         CMDType = "GM",        NeedParam = true,     CMD = "player.GetSelectCharacter().SetModelID(47674)"},
    {text = "[目标] 目标播放特效",                pattern = "[mb]mbbftx",     CMDType = "GM",        NeedParam = true,     CMD = "npc1=player.GetSelectCharacter();npc1.PlaySfx(1055, npc1.nX, npc1.nY, npc1.nZ + 500)"},
    ------------------------------------------------------------------------------>
    {text = "[插旗] 发起插旗",                    pattern = "[cq]fqcq",         CMDType = "GM",        NeedParam = true,     CMD = "target=player.GetSelectCharacter();player.ApplyDuel(target.dwID)"},
    {text = "[插旗] 同意插旗",                    pattern = "[cq]tycq",         CMDType = "GM",        NeedParam = true,     CMD = "player.AcceptDuel(16)"},
    ------------------------------------------------------------------------------>
    {text = "[重载] 重置副本CD",                pattern = "[cz]czfbcd",         CMDType = "Local",    NeedParam = false,     CMD = "RefreshMapCopyNew()"},
    {text = "[重载] 重载脚本含AI",                 pattern = "[cz]czjbhai",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadAllScripts()')"},
    {text = "[重载] 全区服重载脚本含AI",         pattern = "[cz]qcfczjbhai", CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('AllGSCommand(\"ReloadAllScripts()\")')"},
    {text = "[重载] 重载center脚本",             pattern = "[cz]czcenterjb", CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('GCCommand(\"ReloadScripts()\")')"},
    {text = "[重载] 重载OtherItem表",             pattern = "[cz]czitemb",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadOtherItemTab()')"},
    {text = "[重载] 重载UI-Other表",             pattern = "[cz]czuiitemb",     CMDType = "Local",    NeedParam = false,     CMD = "ReloadOtherItemTab()"},
    {text = "[重载] 重载Npc表",                 pattern = "[cz]cznpcb",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadNpcTemplate()')"},
    {text = "[重载] 重载Doodad表",                 pattern = "[cz]czdoodadb",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadDoodadTemplate()')"},
    {text = "[重载] 重载指定脚本",             pattern = "[cz]czzdjb",     CMDType = "GM",        NeedParam = true,     CMD = "ReloadScript('',true) --输入script开始的脚本路径"},
    {text = "[重载] 重载指定技能脚本",             pattern = "[cz]czzdjnjb",     CMDType = "Local",        NeedParam = true,     CMD = "GMMgr.ReloadSkillSinceScriptChanged() --输入技能ID"},
    {text = "[重载] 重载ChatServer脚本",         pattern = "[cz]czchatserverjb",     CMDType = "GM",        NeedParam = true,     CMD = "GCCommand([[ReloadChatServerScript('remote_center.lua')]])"},
    {text = "[重载] 重载Skill表",                 pattern = "[cz]czskillb",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadAllSkill()')"},
    {text = "[重载] 重载Buff表",                 pattern = "[cz]czbuffb",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadAllBuff()')"},
    {text = "[重载] 重载技能位移表",             pattern = "[cz]czjnwyb",     CMDType = "Local",    NeedParam = false,     CMD = "ReloadSkillMove();ReloadTrackMove();SendGMCommand('ReloadSkillMove();ReloadTrackMove()')"},
    {text = "[重载] 重载表现表",                 pattern = "[cz]czbxb",         CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('reload table')"},
    {text = "[重载] 重载RL",                     pattern = "[cz]czrl",         CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('ResetRL')"},
    {text = "[重载] 重载主角UAC",                 pattern = "[cz]czzjuac",     CMDType = "Local",    NeedParam = false,     CMD = "ReloadPlayerUAC()"},
    {text = "[重载] 重载目标AI",                 pattern = "[cz]czmbai",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadAI(player.GetSelectCharacter().GetAIType())')"},
    {text = "[重载] SKM重载GM(第一步)",         pattern = "[cz]skmczgm",     CMDType = "Local",        NeedParam = false,     CMD = "SendGMCommand('ReloadJumpParam()')"},
    {text = "[重载] SKM重载CMD(第二步)",         pattern = "[cz]skmczcmd",     CMDType = "Local",    NeedParam = false,     CMD = "ReloadJumpParam()"},
    {text = "[重载] 重载指定UI脚本含插件",         pattern = "[cz]czzduijbhcj",     CMDType = "Local",    NeedParam = true,     CMD = "LoadScriptFile('/ui/Config/Default/videosettingpanel.lua')"},
    {text = "[重载] 刷新贴图",                     pattern = "[cz]sxtt",         CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('3D reload_textures')"},
    {text = "[重载] 表现配置表_表现行为等",        pattern = "[cz]czbxb",         CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('reload all config table')"},
    {text = "[重载] 重载新手教学",                pattern = "[cz]czxsjx",         CMDType = "Local",    NeedParam = false,     CMD = "TeachEvent.Reload()"},
    {text = "[重载] 重载CD表",                  pattern = "[cz]czcdb",      CMDType = "Local",      NeedParam = false,          CMD = "ReloadCoolDown();SendGMCommand('ReloadCoolDown()')"},
    {text = "[重载] 重载Rust状态机",            pattern = "[cz]czrust",     CMDType = "Local",      NeedParam = false,          CMD = "rlcmd('reload all rust')"},
    ------------------------------------------------------------------------------>
    {text = "[输出] 目标血量内力百分比",         pattern = "[sc]mbxlnlbfb",     CMDType = "GM",     NeedParam = false,     CMD = "npc = player.GetSelectCharacter();npc.Yell('当前血量：'..npc.".._G.CurLife.."..',当前内力：'..npc.nCurrentMana..',血量百分比：'..npc.".._G.CurLife.." / npc.".._G.MaxLife.."..',内力百分比：'..npc.nCurrentMana / npc.nMaxMana)"},
    {text = "[输出] 输出与目标距离",            pattern = "[sc]scymbjl",    CMDType = "GM",        NeedParam = false,     CMD = "player.SendSystemMessage('与目标距离为: '..math.floor(100*GetCharacterDistance(player.dwID,player.GetSelectCharacter().dwID)/64)/100)"},
    {text = "[输出] 输出目标路径ID",            pattern = "[sc]scmbljid",    CMDType = "GM",        NeedParam = false,     CMD = "local tar1=player.GetSelectCharacter();player.SendSystemMessage('目标路径ID为: '..tar1.nPatrolPathID)"},
    {text = "[输出] 输出自身客户端同步的BUFF列表",             pattern = "[sc]sczskhdtbdbufflb", CMDType = "Local",     NeedParam = true,     CMD = "tBuffList = GetBuffList(GetClientPlayer());for i=1,#tBuffList do Output(tBuffList[i]['dwID'],tBuffList[i]['nLevel'],tBuffList[i]['nStackNum'],tBuffList[i]['nIndex']) end"},
    {text = "[输出] 输出副本各进度",             pattern = "[sc]scfbgjd",     CMDType = "GM",     NeedParam = true,     CMD = "scene=player.GetScene();for i=1,8 do print('进度'..i,scene.GetProgress(i)) end"},
    {text = "[输出] 输出目标NPC别名",             pattern = "[sc]scmbbm",        CMDType = "GM",        NeedParam = false,     CMD = "player.SendSystemMessage('目标别名为: '..player.GetSelectCharacter().szName)"},
    {text = "[输出] 输出坐标到服务器",             pattern = "[sc]sczbdfwq",    CMDType = "GM",        NeedParam = false,     CMD = "print('X = ',player.nX,'  ,  Y = ',player.nY,'  ,  Z = ',player.nZ,'  ,  Face = ',player.nFaceDirection)"},
    {text = "[输出] 输出逻辑坐标到客户端",         pattern = "[sc]scljzbdkhd",    CMDType = "Local",     NeedParam = false,     CMD = "local p = GetClientPlayer();OutputMessage('MSG_SYS',p.nX..'  ,  '..p.nY..'  ,  '..p.nZ..'  ,  '..p.nFaceDirection..'\\n')"},
    {text = "[输出] 3D坐标换算逻辑坐标",         pattern = "[sc]3dzbhsljzb",    CMDType = "Local",     NeedParam = true,     CMD = "local x, y, z = Scene_ScenePositionToGameWorldPosition(1,1,1);Goto(x,y,z)"},
    {text = "[输出] 输出指定信息",                pattern = "[sc]sczdxx",         CMDType = "GM",        NeedParam = true,     CMD = "player.SendSystemMessage()"},
    {text = "[输出] 发出GM通知(可输出数据库数据)",            pattern = "[sc]fqgmtz",         CMDType = "GM",        NeedParam = true,     CMD = "GCCommand('SendToPlayerGmAnnounce(\"'..player.szName..'\",tostring(GetGlobalCustomDataManager().Get(\"InstanceFinishedCount\") or nil),1)')"},
    {text = "[输出] 输出周围NPC数量(可指定名字)",             pattern = "[sc]sczwnpcsl", CMDType = "Local", NeedParam = true, CMD = "name='';num=0;for k, v in ipairs(GetNpcList()) do npc = GetNpc(v) if string.find(npc.szName,name) then num=num+1 end end;Output('找到NPC'..name..':'..num..'个!')"},
    {text = "[输出] 输出周围玩家数量(可指定名字)",             pattern = "[sc]sczwwjsl",     CMDType = "Local", NeedParam = true, CMD = "name='';num=0;for k, v in ipairs(GetNearbyPlayerList()) do npc = GetPlayer(v) if string.find(npc.szName,name) then num=num+1 end end;Output('找到玩家'..name..':'..num..'个!')"},
    {text = "[输出] 输出周围指定名字的NPC的ID", pattern = "[sc]sczwzdmzdnpcid", CMDType = "Local", NeedParam = true, CMD = "name='紫晴';for k, v in ipairs(GetNpcList()) do npc = GetNpc(v); if string.find(npc.szName,name) then Output(npc.dwID) end;end"},
    {text = "[输出] 输出目标客户端同步的BUFF列表",         pattern = "[sc]scmbkhdtbdbufflb", CMDType = "Local",     NeedParam = true,     CMD = "type1,id1=GetClientPlayer().GetTarget();npc=GetNpc(id1);if not npc then npc=GetPlayer(id1) end;tBuffList = GetBuffList(npc);for i=1,#tBuffList do Output(tBuffList[i]['dwID'],tBuffList[i]['nLevel'],tBuffList[i]['nStackNum'],tBuffList[i]['nIndex']) end"},
    {text = "[输出] 输出目标BUFF列表含隐藏BUFF",         pattern = "[sc]scmbbufflbhycbuff", CMDType = "Local",     NeedParam = false,     CMD = "GetBuffList_GetSelectCharacter()"},
    {text = "[输出] 时间转日期",                 pattern = "[sc]sjzrq",         CMDType = "Local",     NeedParam = true, CMD = "timenow=1376971200;Output(TimeToDate(timenow)) --GetCurrentTime() 获取当前的time"},
    {text = "[输出] 日期转时间",                 pattern = "[sc]rqzsj",         CMDType = "Local",     NeedParam = true, CMD = "Output(DateToTime(2014,8,20,12,0,0)) --年，月，日，时，分，秒"},
    {text = "[输出] 输出服务器当前时间",         pattern = "[sc]scfwqdqsj",     CMDType = "GM",     NeedParam = false, CMD = "t=TimeToDate(GetCurrentTime());s='服务器当前时间：'..string.format('%d:%d:%d %d:%d:%d', t.year, t.month, t.day, t.hour, t.minute, t.second);SendGlobalSysMsg(s)"},
    {text = "[输出] 输出center-table",             pattern = "[sc]scct",         CMDType = "GM",     NeedParam = true, CMD = "local cmd=[[print(\"----------test\");local t=GetGlobalCustomDataManager().Get('t_Call25GhostTimeList');for k,v in pairs(t) do if type(v)==\"table\" then print(k,#v);for i,j in pairs(v) do print(unpack(j)) end else print(k,v) end end print(\"----------test\")]];GCCommand(cmd)"},
    {text = "[输出] 输出目标LastEntry",         pattern = "[sc]scmblastentry",     CMDType = "GM", NeedParam = true, CMD = "for k,v in pairs(player.GetSelectCharacter().GetLastEntry()) do player.SendSystemMessage(k..':'..v) end"},
    {text = "[输出] 输出场景里战斗中的NPC",     pattern = "[sc]sccjlzdzdnpc",     CMDType = "GM", NeedParam = true, CMD = "tNpc=player.GetScene().GetAllNpc();player.SendSystemMessage('------当前场景战斗中的NPC如下:');for i,npcid in ipairs(tNpc) do local npc=GetNpc(npcid) if  npc and npc.bFightState==true then player.SendSystemMessage('逻辑ID:'..npc.dwID..',模版ID:'..npc.dwTemplateID..','..npc.szName..',坐标:'..npc.nX..','..npc.nY..','..npc.nZ) end end"},
    {text = "[输出] 输出场景里指定重生组的NPC", pattern = "[sc]sccjlzdzszdnpc", CMDType = "GM", NeedParam = true, CMD = "local dwReliveID=1;tNpc=player.GetScene().GetAllNpc();player.SendSystemMessage('------当前查询的是重生组:'..dwReliveID);for i,npcid in ipairs(tNpc) do local npc=GetNpc(npcid) if  npc and npc.dwReliveID==dwReliveID then player.SendSystemMessage('逻辑ID:'..npc.dwID..',模版ID:'..npc.dwTemplateID..','..npc.szName..',坐标:'..npc.nX..','..npc.nY..','..npc.nZ) end end"},
    {text = "[输出] 输出场景里指定ID的", pattern = "[sc]sccjlzdidddoodad", CMDType = "GM", NeedParam = true, CMD = "local tNeed={182,174};local t=player.GetScene().GetAllDoodad();for i,j in pairs(t) do local d1=GetDoodad(j);local b1=false;for k,v in ipairs(tNeed) do if d1.dwTemplateID==v then b1=true break end end;if #tNeed==0 then b1=true end;if b1 then print(d1.dwID,d1.szName,d1.nX,d1.nY,d1.nZ) end end --tNeed不填则是输出全部"},
    ------------------------------------------------------------------------------>
    {text = "[传送] 传送到别名NPC位置",        pattern = "[cs]csdbmnpcwz",        CMDType = "GM",        NeedParam = true,     CMD = "szName='';t=player.GetScene().GetNpcByNickName(szName);player.SetPosition(t.nX, t.nY, t.nZ)"},
    {text = "[传送] 传送到别名DOODAD位置",    pattern = "[cs]csdbmdoodadwz",    CMDType = "GM",        NeedParam = true,     CMD = "szName='';t=player.GetScene().GetDoodadByNickName(szName);player.SetPosition(t.nX,t.nY,t.nZ)"},
    {text = "[传送] 传送到坐标",                pattern = "[cs]csdzb",         CMDType = "GM",        NeedParam = true,     CMD = "player.SetPosition(1, 1, 1)"},
    {text = "[传送] 传送到地图",                pattern = "[cs]csddt",         CMDType = "GM",        NeedParam = true,     CMD = "player.SwitchMap(ID, 100, 100, 100)"},
    {text = "[其他] 设置地图最大玩家数",        pattern = "[qt]szdtzdwjs",    CMDType = "GM",        NeedParam = true,     CMD = "GCCommand('SetMapMaxPlayerCount(dwMapID,1)')"},
    {text = "[其他] 清除当前技能页",            pattern = "[qt]qcdqjny",    CMDType = "Local",    NeedParam = false,     CMD = "ClearAllActionBar()"},
    {text = "[其他] 使用清除CD技能",             pattern = "[qt]syqccdjn",     CMDType = "GM",        NeedParam = false,     CMD = "if player.GetSkillLevel(613) == 0 then player.LearnSkill(613) else player.CastSkill(613,1) end"},
    {text = "[其他] 学习清除CD技能",             pattern = "[qt]xxqccdjn",     CMDType = "GM",        NeedParam = false,     CMD = "player.ForgetSkill(613);player.LearnSkill(613)"},
    {text = "[其他] 清除指定技能CD",             pattern = "[qt]qczdjncd",     CMDType = "GM",        NeedParam = true,     CMD = "player.ClearCDTime(技能的CD的ID)"},
    {text = "[其他] 清除新技能提示",            pattern = "[qt]qcxjnts",     CMDType = "Local",    NeedParam = false,     CMD = "Wnd.CloseWindow('NewSkillBar')"},
    {text = "[帮会] 创建帮会",                    pattern = "[bh]cjbh",         CMDType = "GM",        NeedParam = true,     CMD = "ApplyCreateTong(player.dwID,\"萝莉正太同好会\")"},
    {text = "[帮会] 解散帮会",                     pattern = "[bh]jsbh",         CMDType = "Local",    NeedParam = false,     CMD = "DisbandSelfTong()"},
    {text = "[帮会] 帮会仓库获得大批道具",        pattern = "[bh]hddpdj",        CMDType = "Local",     NeedParam = true,     CMD = "FullfillItem(0) --0表示不创建NPC，1是创建"},
    {text = "[其他] 召唤NPC",                     pattern = "[qt]zhnpc",         CMDType = "GM",        NeedParam = true,     CMD = "player.GetScene().CreateNpc(ID, player.nX,  player.nY, player.nZ, 0,-1,'npcbieming')"},
    {text = "[其他] 召唤一批随机站立NPC",         pattern = "[qt]zhypsjzlnpc",CMDType = "GM",        NeedParam = true,     CMD = "need=50;ID=24538;local s=player.GetScene();local c,d=0,0;for i=1,need do local x,y,z,nf=player.nX,player.nY,player.nZ,player.nFaceDirection;local a=math.floor(math.random(5000,150000)/10000);local b=math.floor(math.random(-2550000,2550000)/10000);local x=x+a*64*math.cos((nf+b)*math.pi/255);local y=y+a*64*math.sin((nf+b)*math.pi/255);local t=s.GetNpcByNickName('newnpc'..i);if not t then s.CreateNpc(ID,x,y,z,0,-1,'newnpc'..i);c=c+1 else d=d+1 end end;player.SendSystemMessage('Add npc:'..c..'  has npc:'..d)"},
    {text = "[其他] 创建一批平行站立NPC",         pattern = "[qt]cjyppxzlnpc",CMDType = "GM",        NeedParam = true,     CMD = "rowneed=5;lineneed=5;ID=5619;local s=player.GetScene();local x,y,z,a,b=player.nX,player.nY,player.nZ,0,0;for i=1,rowneed do for j=1,lineneed do local x=x+i*64*2;local y=y+j*64*2;local t=s.GetNpcByNickName('npc'..i..'_'..j);if not t then s.CreateNpc(ID,x,y,z,0,-1,'npc'..i..'_'..j);a=a+1 else b=b+1 end end end;player.SendSystemMessage('Add npc:'..a..'  has npc:'..b)"},
    {text = "[其他] 平行站立NPC批量消失",         pattern = "[qt]pxzlnpcplxs",CMDType = "GM",        NeedParam = true,     CMD = "rowneed=5;lineneed=5;local s=player.GetScene();for i=1,rowneed do for j=1,lineneed do local t=s.GetNpcByNickName('npc'..i..'_'..j);t.SetDisappearFrames(1,0) end end"},
    {text = "[其他] 随机站立NPC批量消失",         pattern = "[qt]sjzlnpcplxs",CMDType = "GM",        NeedParam = true,     CMD = "need=50;local s=player.GetScene();for i=1,need do local n=s.GetNpcByNickName('newnpc'..i);if n then n.SetDisappearFrames(1,0);print('newnpc'..i..':SetDisappear') end end"},
    {text = "[其他] 召唤Doodad",                 pattern = "[qt]zhdoodad",     CMDType = "GM",        NeedParam = true,     CMD = "player.GetScene().CreateDoodad(ID, player.nX,  player.nY, player.nZ, 0,'doodadbieming')"},
    {text = "[其他] 激活探索Doodad",             pattern = "[qt]jhtsdoodad",     CMDType = "GM",        NeedParam = true,     CMD = "player.ForceActiveExploration(ID) --输入探索模板ID"},
    {text = "[其他] 强制重置指定探索实例",             pattern = "[qt]qzcztssl",     CMDType = "GM",        NeedParam = true,     CMD = "player.ForceResetExploration(ID) --输入探索模板ID"},
    {text = "[其他] 召唤修理商",                 pattern = "[qt]zhxls",         CMDType = "Local",    NeedParam = false,     CMD = "RepairAllItemsNew()"},
    {text = "[其他] 清空奇遇cd",                 pattern = "[qt]qkqycd",     CMDType = "GM",     NeedParam = false,     CMD = "GCCommand(\"GetGlobalCustomDataManager().Set('g_QYCheckList',nil)\")"},
    {text = "[其他] 减少马匹饱食度",             pattern = "[qt]jsmpbsd",     CMDType = "GM",     NeedParam = true,     CMD = "player.CostHorseFullMeasure(INVENTORY_INDEX.HORSE, 0, 100) --参数2 马背包第几格 参数3 饱食度"},
    {text = "[其他] 增加马匹饱食度",             pattern = "[qt]zjmpbsd",     CMDType = "GM",     NeedParam = true,     CMD = "player.AddHorseFullMeasure(INVENTORY_INDEX.HORSE, 0, 100) --参数2 马背包第几格 参数3 饱食度"},
    {text = "[其他] 播放指定协议动画",             pattern = "[qt]bfzdxydh",     CMDType = "GM",     NeedParam = true,     CMD = "RemoteCallToClient(player.dwID, 'OnPlayProtocolMovie', id, false) --id参考 represent/common/movie.krl.txt"},
    {text = "[其他] 脚本ID转脚本名",             pattern = "[qt]jbidzjbm",     CMDType = "GM",        NeedParam = true,     CMD = "local dwScriptID=858298;local szName=GetScriptNameByID(dwScriptID) or '未获取到';player.SendSystemMessage(szName)"},
    --{text = "[其他] 脚本名转脚本ID",             pattern = "[qt]jbmzjbid",     CMDType = "GM",        NeedParam = true,     CMD = "local szFileName='scripts\\Map\\秦皇陵\\skill\\判定挂游泳buff.lua';local dwID=GetFileNameHash(szFileName) or '路径无法转换成ID';player.SendSystemMessage(dwID) --szFileName必须是scripts下的路径，如scripts\\item\\装备成长.lua"},--注意，由于服务器启动时已将所有脚本运算了一次哈希ID占用，这里输入路径再算会是新ID
    {text = "[其他] 破坏据点里所有状态机",         pattern = "[qt]phjdlsyztj", CMDType = "Local",    NeedParam = false,     CMD = "DestroyAllZTJ()"},
    {text = "[其他] 恢复据点里所有状态机",         pattern = "[qt]hfjdlsyztj", CMDType = "Local",    NeedParam = false,     CMD = "FixAllZTJ()"},
    {text = "[其他] 开始教学",                  pattern = "[qt]ksjx",           CMDType = "Local",    NeedParam = true,     CMD = "TeachEvent.TeachStart(501)"},
    {text = "[其他] 检测条件开始教学",           pattern = "[qt]jctjksjx",           CMDType = "Local",    NeedParam = true,     CMD = "if TeachEvent.CheckCondition(501) then TeachEvent.TeachStart(501) end"},
    {text = "[其他] 关闭教学",                  pattern = "[qt]gbjx",           CMDType = "Local",    NeedParam = true,     CMD = "TeachEvent.TeachClose(501)"},
    {text = "[其他] 关闭所有教学",                pattern = "[qt]gbsyjx",           CMDType = "Local",    NeedParam = false,     CMD = "TeachEvent.CloseAllTeach()"},
    {text = "[其他] 监测教学条件检测情况",        pattern = "[qt]jcjxtjjcqk",    CMDType = "Local",    NeedParam = true,     CMD = "TeachEvent.SetMonitorTeachConditionCheck(501)"},
    {text = "[其他] 清除教学状态",                pattern = "[qt]qcjxzt",       CMDType = "Local",    NeedParam = true,     CMD = "TeachEvent.ClearTeachState(501)"},
    {text = "[其他] 清除所有教学状态",             pattern = "[qt]qcsyjxzt",   CMDType = "Local",    NeedParam = false,     CMD = "TeachEvent.ClearAllTeachState()"},
    {text = "[其他] 清除教学变量",              pattern = "[qt]qcjxbl",      CMDType = "Local",    NeedParam = true,     CMD = "TeachEvent.ClearVariable(\"名称\")"},
    {text = "[其他] 清除所有教学变量",           pattern = "[qt]qcsyjxbl",   CMDType = "Local",    NeedParam = false,     CMD = "TeachEvent.ClearAllVariable()"},
    {text = "[其他] 打印教学条件检测记录信息",     pattern = "[sc]dyjxtjjcjlxx",  CMDType = "Local",      NeedParam = true,     CMD = "TeachEvent.PrintConditionCheckResult(501)"},
    {text = "[其他] 打印运行中教学状态",           pattern = "[sc]dyyxzjxzt",   CMDType = "Local",    NeedParam = false,     CMD = "TeachEvent.PrintTeachingInfoStr()"},
    {text = "[其他] 打印所有教学状态",           pattern = "[sc]dysyjxzt",   CMDType = "Local",      NeedParam = false,     CMD = "TeachEvent.PrintTeachStateInfoStr(true)"},
    {text = "[其他] 打印对象池状态",           pattern = "[sc]dydxczt",   CMDType = "Local",      NeedParam = false,     CMD = "PrefabPool.GM_PrintPoolInfo()"},
    {text = "[其他] 打印对象池详细信息",           pattern = "[sc]dydxcxxxx",   CMDType = "Local",      NeedParam = true,     CMD = "PrefabPool.GM_PrintPoolDetailInfo(nID)"},
    {text = "[其他] 对象池调试打印",           pattern = "[sc]kqdxctsdy",   CMDType = "Local",      NeedParam = true,     CMD = "PrefabPool.GM_SetDebugEnable(true)"},
    {text = "[技艺] 学会所有生活技能",            pattern = "[jy]xhshjy",        CMDType = "GM",        NeedParam = false,     CMD = "for i = 1, 7 do player.LearnProfession(i) end; player.LearnProfession(14);"},
    {text = "[技艺] 生活技能满级",                pattern = "[jy]shjnmj",        CMDType = "GM",        NeedParam = false,     CMD = "for i=1, 7 do player.AddProfessionProficiency(i, 99999) end; player.AddProfessionProficiency(14, 99999);"},
    {text = "[技艺] 召唤技艺训练师",            pattern = "[jy]zhjyxls",    CMDType = "GM",        NeedParam = false,     CMD = "local tNpc = {9869,9875,9879,9877,9876,9769,9880,36787} for n, id in ipairs(tNpc) do player.GetScene().CreateNpc(id,player.nX + n * 100,player.nY,player.nZ,0,-1) end"},
    {text = "[技艺] 制造所需doodad和道具",        pattern = "[jy]zzsdj",        CMDType = "GM",        NeedParam = false,     CMD = "player.AddItem(5,20385);local tDoodad = {183, 343, 344, 4768} for n, id in ipairs(tDoodad) do player.GetScene().CreateDoodad(id,player.nX + n * 100,player.nY,player.nZ,0) end"},
    {text = "[技艺] 获取配方相关材料",            pattern = "[jy]hqpfxgcl",    CMDType = "GM",        NeedParam = true,      CMD = "local tRecipe=GetRecipe(5,1);for i=1,8 do if tRecipe[\"dwRequireItemIndex\" ..i]~=\" \" and tRecipe[\"dwRequireItemIndex\" ..i]~=0 then player.AddItem(5,tRecipe[\"dwRequireItemIndex\" ..i]) end end"},
    ------------------------------------------------------------------------------>
    {text = "[表现] 改变天空盒表现",             pattern = "[bx]gbtkhbx",     CMDType = "Local",    NeedParam = true,     CMD = "rlcmd('load custom environment 1')"},
    {text = "[表现] 改变天气表现",                 pattern = "[bx]gbtqbx",     CMDType = "Local",    NeedParam = true,     CMD = "rlcmd('Play dynamicWeather 111') --111雨，30雪，1日夜"},
    {text = "[表现] 恢复默认天空盒天气",         pattern = "[bx]hfmrtkhtq",     CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('reset default environment')"},
    {text = "[表现] 切换NPC为旧模型显示",         pattern = "[bx]qhnpcwjmxxs", CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('use hd 0')"},
    {text = "[表现] 切换NPC为新模型显示",         pattern = "[bx]qhnpcwxmxxs", CMDType = "Local",    NeedParam = false,     CMD = "rlcmd('use hd 1')"},

    {text = "[表现] 重加载资源转换表",         pattern = "[bx]czzyzhb", CMDType = "Local",    NeedParam = true,     CMD = "rlcmd('reload resource convert')"},
    {text = "[表现] 资源转换调试模式",         pattern = "[bx]zyzhts", CMDType = "Local",    NeedParam = true,     CMD = "rlcmd('debug resource convert 0') --0表示关闭，1表示开启"},

    {text = "[副本] 设置副本进度",                 pattern = "[fb]szfbjd",     CMDType = "GM",     NeedParam = true,     CMD = "scene=player.GetScene();for i=1,8 do scene.SetProgress(i,true) end"},
    {text = "[掉落] 目标掉落为自己",             pattern = "[dl]mbdlwzj",     CMDType = "GM",     NeedParam = false,     CMD = "player.GetSelectCharacter().dwOwner=player.dwID;player.GetSelectCharacter().dwDropTargetPlayerID=player.dwID"},

    {text = "[副本] 缓存个人进度信息到GS",     pattern = "[fb]hcgrjdxxdgs", CMDType = "GM",     NeedParam = true,     CMD = "scene=player.GetScene();ApplyDungeonRoleProgress(scene.dwMapID, scene.nCopyIndex, player.dwID) --玩家必须是在副本里"},
    {text = "[副本] 获取个人进度信息",         pattern = "[fb]hqgrjdxx",      CMDType = "GM",     NeedParam = true,     CMD = "scene=player.GetScene();for nProgressID=1,12 do player.SendSystemMessage(nProgressID..':'..tostring(scene.GetDungeonRoleProgress(player.dwID,nProgressID))) end --每进一个新拷贝本必须先缓存再获取"},
    {text = "[副本] 清除指定BOSS全团个人进度信息",     pattern = "[fb]qczdbossqtgrjdxx", CMDType = "GM",     NeedParam = true,     CMD = "for nProgressID=1,10 do PlayerList=player.GetScene().GetAllPlayer();nPlayerCount=#PlayerList;scene=player.GetScene();SetDungeonRoleProgress(scene.dwMapID,scene.nCopyIndex,nProgressID,false,nPlayerCount,PlayerList) end--要清除的玩家都必须是在副本里"},
    {text = "[副本] 清除指定BOSS自身个人进度信息",     pattern = "[fb]qczdbosszsgrjdxx", CMDType = "GM",     NeedParam = true,     CMD = "for nProgressID=1,10 do PlayerList={player.dwID};nPlayerCount=#PlayerList;scene=player.GetScene();SetDungeonRoleProgress(scene.dwMapID,scene.nCopyIndex,nProgressID,false,nPlayerCount,PlayerList) end--要清除的玩家都必须是在副本里"},
    {text = "[副本] 设置指定BOSS全团个人进度信息",     pattern = "[fb]szzdbossqtgrjdxx", CMDType = "GM",     NeedParam = true,     CMD = "for nProgressID=1,10 do PlayerList=player.GetScene().GetAllPlayer();nPlayerCount=#PlayerList;scene=player.GetScene();SetDungeonRoleProgress(scene.dwMapID,scene.nCopyIndex,nProgressID,true,nPlayerCount,PlayerList) end--要设置的玩家都必须是在副本里"},
    {text = "[副本] 设置指定BOSS自身个人进度信息",     pattern = "[fb]szzdbosszsgrjdxx", CMDType = "GM",     NeedParam = true,     CMD = "for nProgressID=1,10 do PlayerList={player.dwID};nPlayerCount=#PlayerList;scene=player.GetScene();SetDungeonRoleProgress(scene.dwMapID,scene.nCopyIndex,nProgressID,true,nPlayerCount,PlayerList) end--要设置的玩家都必须是在副本里"},

    {text = "[副本] 远程调用重置副本",         pattern = "[fb]ycdyzzfb",     CMDType = "Local",    NeedParam = true,     CMD = "RemoteCallToServer('OnResetMapRequest', 240) --后面是副本ID"},
    {text = "[任务] 取消不能放弃的任务",     pattern = "[fb]qxbnfqdrw",     CMDType = "GM",    NeedParam = true,     CMD = "local nQID=19293;local nIndex1=player.GetQuestIndex(nQID);player.CancelQuest(nIndex1)"},

    {text = "[帮会] 增加帮会资金",     pattern = "[bh]zjbhzj",     CMDType = "GM",    NeedParam = true,     CMD = "money=10000;GCCommand(string.format('GetTong(%d).AddFund(%d, %d, %d)', player.dwTongID, money, player.dwID, 0))"},
    {text = "[帮会] 设置帮会等级",    pattern = "[bh]szbhdj",    CMDType = "GM",    NeedParam = true,    CMD = "level=7;GCCommand(string.format('GetTong(%d).SetLevel(%d)', player.dwTongID, level))"},
    {text = "[帮会] 点天工树",    pattern = "[bh]dtgs",    CMDType = "GM",    NeedParam = true,    CMD = "index=17;level=1;GCCommand(string.format('GetTong(%d).SetTechNodeLevel(%d, %d)', player.dwTongID, index, level))"},
    {text = "[帮会] 帮会阵营",    pattern = "[bh]bhzy",    CMDType = "GM",    NeedParam = true,    CMD = "camp=CAMP.GOOD;GCCommand(string.format('GetTong(%d).SetCamp(%d)', player.dwTongID, camp)) --NEUTRAL,GOOD,EVIL"},
    {text = "[帮会] 菜园保卫战重置为未开始",    pattern = "[bh]cybwzczwwks",    CMDType = "GM",    NeedParam = false,    CMD = "GCCommand('GetTong('..player.dwTongID..').SetCustomInteger4(88,0)') local scene=player.GetScene() if scene.dwMapID~=74 then player.SendSystemMessage('请在帮会领地内使用。') else scene.SetCustomUnsigned4(586,0) end"},
    {text = "[帮会] 小猪快跑重置为未开始",    pattern = "[bh]xzkpczwwks",    CMDType = "GM",    NeedParam = false,    CMD = "GCCommand('GetTong('..player.dwTongID..').SetCustomInteger1(77,0)');GCCommand('GetTong('..player.dwTongID..').SetCustomInteger4(84,0)')"},
    {text = "[帮会] 钓鱼活动重置为未开始",    pattern = "[bh]dyhdczwwks",    CMDType = "GM",    NeedParam = false,    CMD = "GCCommand('GetTong('..player.dwTongID..').SetCustomInteger1(38,0)');GCCommand('GetTong('..player.dwTongID..').SetCustomInteger4(80,0)')"},
    {text = "[西瓜SDK] 初始化",    pattern = "[sdk]xgsdkcsh",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_Init()"},
    {text = "[西瓜SDK] 登录",    pattern = "[sdk]xgsdkdl",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_Login()"},
    {text = "[西瓜SDK] 支付",    pattern = "[sdk]xgsdkzf",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_Pay()"},
    {text = "[西瓜SDK] 支付1",    pattern = "[sdk]xgsdkzf1",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_Pay1()"},
    {text = "[西瓜SDK] 支付2",    pattern = "[sdk]xgsdkzf2",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_Pay2()"},
    {text = "[西瓜SDK] 获取渠道ID",    pattern = "[sdk]xgsdkhqqdid",    CMDType = "Local",    NeedParam = false,    CMD = "XGSDK_GetChannelID()"},
    {text = "[调试] 触发宕机",    pattern = "[ts]cfdj",    CMDType = "Local",    NeedParam = false,    CMD = "TriggerCrash()"},
    {text = "[调试] 触发云游戏宕机",    pattern = "[ts]cfyyxdj",    CMDType = "Local",    NeedParam = false,    CMD = "TriggerCloudAppCrash()"},
    {text = "[好友] 推送好友",    pattern = "[hy]tshy",    CMDType = "GM",    NeedParam = true,    CMD = "GCCommand('PushFellowship(dwRoleID, dwFellowshipType, dwMiniAvatarID, dwForceID, byCampID, byOnlineType)') -- dwRoleID, 249, 0, 4, 1, 1 , 要目标在线才会上推荐。dwFellowshipType是掩码,建议249，不存盘，重启gc后需要重设"},
    {text = "[测试] 本地视频",    pattern = "[cs]bdsp",    CMDType = "Local",    NeedParam = false,    CMD = "MovieMgr.PlayVideo('ui/Video/HefangyiVSYewei.mp4', {bNet=false}); UIMgr.Close(VIEW_ID.PanelGM)"},
    {text = "[测试] 网络视频",    pattern = "[cs]wlsp",    CMDType = "Local",    NeedParam = false,    CMD = "MovieMgr.PlayVideo('http://jx3.xoyo.com/zt/2018/06/20/v/index.html?video=http://v-static.jx3.xoyo.com/video/20180620/gongsunliuwu.webm&init=gq', {bNet=true})"},
    {text = "[测试] 网络视频1",    pattern = "[cs]wlsp",    CMDType = "Local",    NeedParam = false,    CMD = "MovieMgr.PlayVideo('https://video.jx3m.qq.com/Movie/XYDH/DXC/DXC_A_QX.mp4', {bNet=true})"},
    {text = "[测试] 网络视频2",    pattern = "[cs]wlsp2",    CMDType = "Local",    NeedParam = false,    CMD = "MovieMgr.PlayVideo('https://video.jx3m.qq.com/Movie/LoginHeroLarge/QuYunSkillD.mp4', {bNet=true});"},
    {text = "[其他] 显示|关闭 Debug信息",    pattern = "[qt]xsgbdxx",    CMDType = "Local",    NeedParam = false,    CMD = "KG3DEngine.SetMobileEngineOption({bRenderUIDebug = not KG3DEngine.GetMobileEngineOption().bRenderUIDebug})"},
    {text = "[其他] 显示UI内存信息",    pattern = "[qt]xsuincxx",    CMDType = "Local",    NeedParam = false,    CMD = "Debug.DisplayMemoryInfo()"},
    {text = "[其他] 显示UI各种尺寸信息",    pattern = "[qt]xsuigzccxx",    CMDType = "Local",    NeedParam = false,    CMD = "Debug.DisplayUISizeInfo()"},
    {text = "[其他] 显示设备信息",    pattern = "[qt]xssbxx",    CMDType = "Local",    NeedParam = false,    CMD = "Debug.DisplayDeviceInfo()"},
    {text = "[其他] 关闭PakV5 HttpFile",    pattern = "[qt]gbv5",    CMDType = "Local",    NeedParam = false,    CMD = "KG3DEngine.DisablePakV5HttpFile()"},
    {text = "[其他] 打开PakV5 HttpFile",    pattern = "[qt]dkv5",    CMDType = "Local",    NeedParam = false,    CMD = "KG3DEngine.EnablePakV5HttpFile()"},
    {text = "[其他] 强行设置扩展包完成",    pattern = "[qt]szdlc",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.DebugSetPackDownloaded(nPackID)"},
    {text = "[其他] 检测ZsCache",    pattern = "[qt]jczs",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownload_GMCheckZsCache()"},
    {text = "[其他] PakV5测速(死循环)",    pattern = "[qt]cswsv5",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownload_GMTestMaxDownloadSpeed()"},
    {text = "[其他] 打印ZsCache状态",    pattern = "[qt]dyzs",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownload_GMPrintZsCache()"},
    {text = "[其他] 删除ZsCache数据",    pattern = "[qt]sczs",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownload_GM_RemoveFileByFileList()"},
    {text = "[其他] 模拟异常扩展包",    pattern = "[qt]mnyckzb",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownload_GMSetErrorDLC(2)"},
    {text = "[其他] 检测扩展包内容是否完全下载",    pattern = "[qt]jckzbnrsfwqxz",    CMDType = "Local",    NeedParam = true,    CMD = "print(PakDownload_GMCheckDLCContent(1))"},
    {text = "[其他] 开始资源下载流量统计",    pattern = "[qt]kszyxzlltj",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.SetStatisticsEnabled(true) --仅供参考，实际消耗可能会更大"},
    {text = "[其他] 结束资源下载流量统计",    pattern = "[qt]jszyxzlltj",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.SetStatisticsEnabled(false) --仅供参考，实际消耗可能会更大"},
    {text = "[其他] 下载全部资源",    pattern = "[qt]xzqbzy",    CMDType = "Local",    NeedParam = false,    CMD = "local tPackIDList = PakDownloadMgr.GetExtensionPackIDList();for _, nPackID in ipairs(tPackIDList) do PakDownloadMgr.DownloadPack(nPackID) end;"},
    {text = "[其他] 设置资源清理时间",    pattern = "[qt]szzyqlsj",    CMDType = "Local",    NeedParam = true,    CMD = "ResCleanData.GM_SetCleanTime(30*(24*60*60), 90*(24*60*60), 14*(24*60*60), 30*(24*60*60) ) --四个参数分别为外装30天未加载/外装90天未加载/地图14天未进入/地图30天未进入"},
    {text = "[其他] 模拟设置网络状态",    pattern = "[qt]mnszwlzt",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.DebugSetNetMode(2) -- 0:无网络, 1:WIFI, 2:移动网络"},
    {text = "[其他] 强行禁用基础包",    pattern = "[qt]qxjyjcb",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownloadMgr.CancelBasicPack();PakDownloadMgr.DebugSetPackDownloaded(1);PakDownloadMgr.DebugSetEnableBasicPack(false);"},
    {text = "[其他] 强行禁用核心包",    pattern = "[qt]qxjyhxb",    CMDType = "Local",    NeedParam = false,    CMD = "PakDownloadMgr.CancelPack(7);PakDownloadMgr.DebugSetPackDownloaded(7);PakDownloadMgr.DebugSetEnableCorePack(false);"},
    {text = "[其他] 禁用精确获取资源大小",    pattern = "[qt]jyjqhqwjdx",    CMDType = "Local",    NeedParam = true,    CMD = "PakSizeQueryMgr.SetEnabled(false) -- false:禁用, true:启用"},
    {text = "[其他] 禁用资源下载UI更新",    pattern = "[qt]jyzyxzuigx",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.DebugSetEnableUIUpdate(false) -- false:禁用, true:启用"},
    {text = "[其他] 开启资源下载Debug打印",    pattern = "[qt]kqzyxzdebugdy",    CMDType = "Local",    NeedParam = true,    CMD = "PakDownloadMgr.SetDebugMode(true) -- false:禁用, true:启用"},
    {text = "[其他] 设置界面启用UI节点工具",    pattern = "[qt]szjmqyuijdgj",    CMDType = "Local",    NeedParam = true,    CMD = "KeyBoard.tbIngoreOnGameSetting = {18, 37, 38, 39, 40, 120} -- 18:Alt，37:→, 38:↑, 39:←, 40:↓，120:F9"},
    {text = "[测试] 打开主界面CD按钮",    pattern = "[qt]clearCD",    CMDType = "Local",    NeedParam = false,    CMD = "Event.Dispatch(\'ClearCDGMButton\')"},
    {text = "[测试] 打开主界面杀死按钮",    pattern = "[qt]KillTarget",    CMDType = "Local",    NeedParam = false,    CMD = "Event.Dispatch(\'KillTargetGMButton\')"},
    {text = "[其他] 显示客户端版本信息",    pattern = "[qt]xskhdbbxx",    CMDType = "Local",    NeedParam = false,    CMD = "Debug.DisplayClientVerSionInfo()"},
    {text = "[其他] 计算ASCII字符大小",    pattern = "[qt]jsasciizfdx",    CMDType = "Local",    NeedParam = false,    CMD = "GMCMD_CalcASCIIWidth()"},
    {text = "[其他] 环境预设开关",             pattern = "[qt]hjyskg",     CMDType = "Local",     NeedParam = true,     CMD = "rlcmd(\"set env preset 1\")"},
    {text = "[其他] 开启技能录制功能",                pattern = "[qt]kqjnlzgn",      CMDType = "Local",      NeedParam = false,         CMD = "require(\"Lua/Debug/GM/AutoTest/SkillDamageStatistics/SkillsRecording.lua\");SkillsRecording:Init()"},
    {text = "[其他] 自动化测试",                pattern = "[qt]autotest",      CMDType = "Local",      NeedParam = false,         CMD = "require(\"Lua/Debug/GM/AutoTest/AutoTestEnv.lua\");"},
    {text = "[其他] UI节点工具",                pattern = "[qt]uijdgj",      CMDType = "Local",      NeedParam = false,         CMD = "GMCMD_OpenNodeExplorer();"},
    {text = "[其他] 测试标记开与关",                pattern = "[qt]csbjkyg",      CMDType = "Local",      NeedParam = false,         CMD = "GMCMD_UpdateCEVerFlag();"},
    {text = "[其他] 配置地图资源收集环境",                pattern = "[qt]pzdtzysjhj",      CMDType = "Local",      NeedParam = false,         CMD = "require(\"Lua/Debug/GM/CollectMapEnv.lua\");CollectMapEnv.Init()"},
    {text = "[其他] 模拟连接手柄",                pattern = "[qt]mnljsb",      CMDType = "Local",      NeedParam = true,         CMD = "GamepadData.ResumeInput();\nGamepadData.GetGamepadType = function() return 3 end;--0:无,1:PS4,2:PS5,3:XBOX,4:Switch"},
    {text = "[其他] 模拟AR模式",                pattern = "[qt]mnarms",      CMDType = "Local",      NeedParam = true,         CMD = "IsDeviceAvailableCamera=function() return true end;GetCameraCaptureState=function() return 2 end; --1关闭 2开启"},
    {text = "[BVT测试] 传送到布娃娃位置",	pattern = "[bvt]bww",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,45500,72894,1085184) else player.SetPosition(45500,72894,1085184) end"},
    {text = "[BVT测试] 传送到山贼营地附近",	pattern = "[bvt]szyd",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,73648,62600,1052416) else player.SetPosition(73648,62600,1052416) end"},
    {text = "[BVT测试] 传送到稻香蟹附近",	pattern = "[bvt]dxx",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,77261,63016,1048896) else player.SetPosition(77261,63016,1048896) end"},
    {text = "[BVT测试] 传送到疯子巡逻路径",	pattern = "[bvt]fz",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,43612,69983,1086144) else player.SetPosition(43612,69983,1086144) end"},
    {text = "[BVT测试] 传送到村长等NPC附近",	pattern = "[bvt]lynpc",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,52912,72987,1074752) else player.SetPosition(52912,72987,1074752) end"},
    {text = "[BVT测试] 传送到远景检查点",	pattern = "[bvt]yj",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,55709,92983,1095936) else player.SetPosition(55709,92983,1095936) end"},
    {text = "[BVT测试] 传送到水面检查点",	pattern = "[bvt]sm",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,65226,49175,1049984) else player.SetPosition(65226,49175,1049984) end"},
    {text = "[BVT测试] 传送到瀑布检查点",	pattern = "[bvt]pb",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,70129,49191,1049472) else player.SetPosition(70129,49191,1049472) end"},
    {text = "[BVT测试] 传送到成就Trap点",	pattern = "[bvt]cj",	CMDType = "GM",	NeedParam = false,	CMD = "if player.GetMapID() ~= 653 then player.SwitchMap(653,54943,73677,1098944) else player.SetPosition(54943,73677,1098944) end"},
    {text = "[BVT测试] 传送到张桂芝附近并加钱",	pattern = "[bvt]zgz",	CMDType = "GM",	NeedParam = false,	CMD = "player.AddMoney(1000,0,0);if player.GetMapID() ~= 653 then player.SwitchMap(653,52878,74233,1074944) else player.SetPosition(52878,74233,1074944) end"},
    {text = "[BVT测试] 添加飞鱼丸所需材料",	pattern = "[bvt]fyw",	CMDType = "GM",	NeedParam = false,	CMD = "local tfywcl={30837,31998,30834,30840,30833};for k,v in pairs(tfywcl) do player.AddItem(5,v) end"},
    {text = "[BVT测试] 设置自己为1点血量",	pattern = "[bvt]zjxl",	CMDType = "GM",	NeedParam = false,	CMD = "player.nCurrentLife = 1"},
    {text = "[BVT测试] 传送到万花电梯附近",	pattern = "[bvt]whdt",	CMDType = "GM",	NeedParam = false,	CMD = "player.SwitchMap(2,54707,36026,1202112)"},
    {text = "[任务] 查看任务状态",     pattern = "[rw]ckrwzt",     CMDType = "GM",    NeedParam = true,     CMD = "local i = 30112; t = player.GetQuestPhase(i) player.SendSystemMessage(t) print(i, t)"},
    {text = "[任务] 查看令牌状态",     pattern = "[rw]cklpzt",     CMDType = "GM",    NeedParam = true,     CMD = "local i = 23; t = player.GetSceneFilter(i) print(i, t)"},
    {text = "[任务] 设置任务变量",     pattern = "[rw]szrwbl",     CMDType = "GM",    NeedParam = true,     CMD = "i=player.GetQuestIndex(30112);player.SetQuestValue(i, 0, 1)  -- 任务ID，序号(从0起)，变量" },
    {text = "[任务] 设置地图令牌",     pattern = "[rw]szdtlp",     CMDType = "GM",    NeedParam = true,     CMD = "local i, k, v = 653, 0, true; CustomFunction.SetSceneFilter(player, i, k, v) -- 地图，令牌id，true开启false关闭"},
    {text = "[密保锁] 强制解锁",	pattern = "[mbs]qzjs",	CMDType = "GM",	NeedParam = false,	CMD = "player.ModifySafeLockMask(131071)"},
    {text = "[AIAgentChat] 与NPC聊天",  pattern = "[aiagent]npc",        CMDType = "Local", NeedParam = true,     CMD = "GMCMD_AIAgentChatWithNpc(96, '东方宇轩', '你知道奇遇是什么吗，怎样才能遇到呢？');"},
    {text = "[AIAgentChat] 与当前选中NPC聊天",  pattern = "[aiagent]selected",        CMDType = "Local", NeedParam = true,     CMD = "GMCMD_AIAgentChatWithSelectedNpc('你知道奇遇是什么吗，怎样才能遇到呢？');"},
}

local tExCmd
if not _G.bClassic then
    tExCmd = {
        {text = "[输出] 输出3D坐标到客户端",         pattern = "[sc]sc3dzbdkhd",    CMDType = "Local",     NeedParam = false,     CMD = "local p=GetClientPlayer();PostThreadCall(GetCallBackFun(), nil, 'Scene_GameWorldPositionToScenePosition',p.nX,p.nY,p.nZ);"},
    }
else
    tExCmd = {
        {text = "[输出] 输出3D坐标到客户端",         pattern = "[sc]sc3dzbdkhd",    CMDType = "Local",     NeedParam = false,     CMD = "local p=GetClientPlayer(); Output(Scene_GameWorldPositionToScenePosition(p.nX,p.nY,p.nZ,true))"},
    }

end
for index,tNow in ipairs(tExCmd) do
    table.insert(tGMCMD,tNow)
end

if IsExistEtagDataSrc and IsExistEtagDataSrc() then    -- 开启etag模式
    table.insert(tGMCMD, 3, {text = "[其他] 清ETag数据", pattern = "[qt]etag", CMDType = "Local", NeedParam = false, CMD = "ClearRuntimeEtagInfo()"})
end

----------------------------------自定义接口
function DeleteAllItem()
    TipsHelper.OutputMessage("MSG_SYS","DeleteAllItem working!\n")
    local player = player or GetClientPlayer()
    for i = 1, INVENTORY_INDEX.TOTAL - 1 do
--~         if i ~= INVENTORY_INDEX.HORSE then
        if player.GetBoxType(i) ~= INVENTORY_TYPE.HORSE_PACKAGE then
            for j = 0, player.GetBoxSize(i) - 1 do
                local item = player.GetItem(i, j)
                if item then
                    if item.dwTabType == ITEM_TABLE_TYPE.OTHER and  item.dwIndex  == 3666 then                --item.nSub ~= EQUIPMENT_SUB.PACKAGE and item.dwTabType ~= EQUIPMENT_SUB.HORSE then
                        TipsHelper.OutputMessage("MSG_SYS","find 5,3666!保留该道具!\n")
                    else
                        DestroyItem(i, j) --本地指令无效！
                        --SendGMCommand("player.DestroyItem("..i..","..j..")")
                    end
                end
            end
        end
    end
end



function DealWithOr(a, b)
	if a and a ~= "" then
		return a
	end
	if b and b ~= "" then
		return b
	end
	return nil
end

function ParseServerState(nState)
	local nServerState = nState
	local nCommendState = nState
	if nState >= 10 then --为了兼容新旧版本～
		nServerState =  math.floor(nState / 10)
		nCommendState = math.floor(nState % 10)
	end

	return nServerState, nCommendState
end

local function GetCurrentServerInfo()
	local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
	local tbSelectServer = LoginServerList.GetSelectServer()
	return tbSelectServer.szIP, tbSelectServer.szRegion
end

function AddTempServer(IP, ServerName)
    local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local aServer = {}
    local szRegion = "常用"
    local szServer = UIHelper.GBKToUTF8(ServerName)
    aServer[1] = szRegion                           --szSimpleRegion
    aServer[2] = szServer                           --szServer
    aServer[3] = "1"                                --nState
    aServer[4] = IP                                 --szIP
    aServer[5] = "3724"                             --nPort
    aServer[6] = szRegion                           --szDisplayRegion
    aServer[7] = szServer                           --szDisplayServer
    aServer[8] = "0"                                --nAreaID
    aServer[9] = "0"                                --nGroupID
    aServer[10] = "z01"                             --szSerial
    aServer[11] = szServer                          --szRealServer
    aServer[12] = szRegion                          --szRegion
    aServer[13] = nil                               --szStatePath
    aServer[14] = nil                               --nStateFrame
    aServer[15] = nil                               --bPvp
    aServer[16] = 0
    table.insert(G_UIServerListTab, aServer)
    LoginServerList.RequestServerList()
end

tMyCanRepairPos ={
        [0] = EQUIPMENT_INVENTORY.MELEE_WEAPON,     --近战武器0
        [1] = EQUIPMENT_INVENTORY.BIG_SWORD,    --重剑 1
        [2] = EQUIPMENT_INVENTORY.RANGE_WEAPON,    --远程武器
        [3] = EQUIPMENT_INVENTORY.CHEST,            --上衣
        [4] = EQUIPMENT_INVENTORY.HELM,                --头盔
        [8] = EQUIPMENT_INVENTORY.WAIST,            --腰带
        [10] = EQUIPMENT_INVENTORY.PANTS,            --裤子
        [11] = EQUIPMENT_INVENTORY.BOOTS,            --鞋子
        [12] = EQUIPMENT_INVENTORY.BANGLE,            --护手
        }

function RepairAllItemsNew()
    local player = GetClientPlayer()
    local bNeed = false
    local npcid = 17
    for i, ePos in pairs(tMyCanRepairPos) do
        local Item3 = player.GetEquipItem(ePos)
        if Item3 and Item3.nCurrentDurability ~= Item3.nMaxDurability then
            bNeed = true
            break
        end
    end
    if bNeed == true then
        SendGMCommand("player.GetScene().CreateNpc("..npcid..", player.nX+100,  player.nY+100, player.nZ, 0,160,'xls')")
        bNeed = false
    else
        OutputMessage("MSG_SYS","当前无装备需要修理!\n")
    end
end

function PlayerLevelUpToNew(Level)
--~     SendGMCommand("player.SendSystemMessage(player.nMaxLevel)")
    local nExpLevel = tonumber(Level)
    local player = GetClientPlayer()
    local nCurLevel = player.nLevel
    if nExpLevel < nCurLevel then
        return
    end
    local nExpNeedToAdd = -player.nExperience
    for num=nCurLevel,nExpLevel,1 do
        if not GMMgr and not GMMgr.GetLevelUpData_New then
            OutputMessage("MSG_SYS","GMMgr.GetLevelUpData_New接口找不到！")
            return
        end
        local roleTypeNow = player.nRoleType
        if not GMMgr.LevelUpData[roleTypeNow] then --这时GMTools.LevelUpData不会不存在
            GMMgr.LevelUpData_Load(roleTypeNow) --s-----------实现使用时即时加载表
        end
        local nLevelExp = tonumber(GMMgr.GetLevelUpData_New(roleTypeNow, num - 1).Experience) or 1
        nExpNeedToAdd = nExpNeedToAdd + nLevelExp
    end
    SendGMCommand("player.AddExp("..nExpNeedToAdd..")")
end

function RefreshMapCopyNew()
    local szMapName = g_pClientPlayer and g_pClientPlayer.GetScene().szName or ""
    local szMessage = string.format("确定重载当前地图 [%s] 吗", UIHelper.GBKToUTF8(szMapName))
    UIHelper.ShowConfirm(szMessage, function()
        SendGMCommand(UIHelper.UTF8ToGBK("if (player.GetScene().dwMapID~=1 and player.GetScene().dwMapID~=653) then GCCommand('RefreshMapCopy('..player.GetScene().dwMapID..','..player.GetScene().nCopyIndex..')') else player.SendSystemMessage('[警告]哥们,稻香村不允许重载!') end"))
    end)
end

function ConfigNewRole(forceID,MountKungfu,nCamp,RecipeTab)
    -- 注册一个配置角色完成事件
    Event.Reg(GMMgr, "ROLE_CONFIG_END", function ()
        SendGMCommand("player.GMClearSetToSlotToSkillList()")
        local szMessage = "角色配置完成, 请返回选角界面重新登入"
        UIHelper.ShowConfirm(szMessage, function ()
            GMMgr.DelayCall(1, function()
                Global.BackToLogin(true)
                Event.UnReg(GMMgr, "ROLE_CONFIG_END")
            end) --延时
        end)
    end)

    --先遗忘旧门派的秘籍, 如果配置的心法为本门派就简化步骤
    local player = GetClientPlayer()
    local OldForceID = player.dwForceID
    local bNewForce = forceID ~= OldForceID
    if GMMgr and bNewForce then
        if not GMMgr.Recipe then
            GMMgr.Recipe_Load() --s-----------实现使用时即时加载表，表较大会卡一下
        end
        if GMMgr.Recipe and GMMgr.SearchRecipe then
            local OldRecipeTab = GMMgr.SearchRecipe(OldForceID,0)
            --TODO:这里有问题，这里读的是端游的秘籍表，可能要改为手游秘籍表
            for i = 1, #OldRecipeTab do
                SendGMCommand("player.DelSkillRecipe("..OldRecipeTab[i].RecipeID..","..OldRecipeTab[i].RecipeLevel..")")
            end
        end

        -- 加一个遗忘原来的移动端心法和技能
        local OldKungfu = ForceIDToKungfuIDs(OldForceID)
        for _, KungfuID in ipairs(OldKungfu) do
            if not TabHelper.IsHDKungfuID(KungfuID) then
                local CurrentPlayerSkillList = SkillData.GetCurrentPlayerSkillList(KungfuID)
                for _, SkillData in ipairs(CurrentPlayerSkillList) do
                    SendGMCommand("player.ForgetSkill(".. SkillData.nID ..")")
                end
                SendGMCommand("player.ForgetSkill(".. KungfuID ..")")
            end
        end
    end

    local fnLevelup = function()
        SendGMCommand("player.SetForceID("..forceID..")") --设置门派
        SendGMCommand("local t = {706,1,2,3,4,5,6,7,8,1006, 980, 1877, 840, 841, 99, 100, 101, 102, 103, 713, 3434,719,132,35,90,374,3450,3451};for i=1,#t do player.AcquireAchievement(t[i]) end") --升级前先加成就，避免获取成就太快的报错
        local LevelNeed = 130
        if _G.bClassic then
            LevelNeed = 70
        end
        PlayerLevelUpToNew(LevelNeed) --升级到120
        SendGMCommand("player.SetCamp("..nCamp..")") --设置阵营
    end

    local fnLearnSkill = function()
        SendGMCommand("local tB={9319,9320,9321,9322};if player.dwForceID~=22 then for i=1,#tB do player.DelMultiGroupBuffByID(tB[i]) end end") --清除长歌表现BUFF
        SendGMCommand("local tB={14487,14490,14491,14492,14493,14494};if player.dwForceID~=24 then for i=1,#tB do player.DelMultiGroupBuffByID(tB[i]) end end") --清除蓬莱表现BUFF
        local newKungfu = ForceIDToKungfuIDs(forceID)
        -- 补充一个学习门派心法
        for _, KungfuID in ipairs(newKungfu) do
            SendGMCommand("player.LearnSkill(".. KungfuID ..")")
        end
        if not _G.bClassic then
            --少林(6230,2)无效，暂时改为(6230,1)
            SendGMCommand("player.CastSkill(6230,1)")    --学习所有技能
        else
            OutputMessage("MSG_SYS","怀旧版无6230技能，无法学习所有技能，导致切门派失败!启用无名剑方式解决！\n")
        end
        SendGMCommand("player.AddTrain(100000)") --加10W修为
        -- 端游逻辑要改手游, 先暂时屏蔽
        --MessageBox({szMessage="确定清空背包吗？无论何种选择，4秒后自动添加武器！",szName="DeleteAllItem",fnAutoClose=function() end,{szOption = "没错,清空！", fnAction = DeleteAllItem},{szOption = "不了,手误!"}})
        local szMessage = "确定清空背包吗？无论何种选择，4秒后自动添加武器！"
        UIHelper.ShowConfirm(szMessage, function () DeleteAllItem() end)
        if forceID and forceID == 21 then
            SendGMCommand("player.AddBuff(player.dwID,player.nLevel,8277,1)") --解决切苍云后几率出现不能使用盾飞的问题
        end
        SendGMCommand("if player.GetSkillLevel(613) == 0 then player.LearnSkill(613) end") --学习清CD技能
    end

--~     DeleteAllItem() --删除背包道具
--~     --解锁奇穴任务，目前不需要了
--~     SendGMCommand("local index={14746,14754};for i,qid in ipairs(index) do player.AcceptQuest(1,1,qid,1) end")
--~     local function forceQuest()
--~         SendGMCommand("local index={14746,14754};for i,qid in ipairs(index) do player.ForceFinishQuest(qid) end")
--~     end
--~     DelayCall(500,forceQuest)

    local nMainPackageSize = player.GetBoxSize(INVENTORY_INDEX.PACKAGE)
    local titemindexTM = {4000,4000,4000,4000,4000,4014,4014,4014,4014,4014} --唐门特供，子弹机关
    local titemtypeTM = 6
    local function mountitem(index)
--~             Output("mountitem",titemindexTM,titemtypeTM) --闭包，不用传入参数，可以找到上层变量
        local player = GetClientPlayer()
        for i=0,nMainPackageSize-1 do
            local item = player.GetItem(INVENTORY_INDEX.PACKAGE, i)
            if item then
                if item.dwTabType==titemtypeTM and item.dwIndex == titemindexTM[index] then
                    player.ExchangeItem(INVENTORY_INDEX.PACKAGE,i,INVENTORY_INDEX.BULLET_PACKAGE,index)
                    break
                    --OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
                end
            end
        end
    end

    local fnMountKungfu = function()
        local player = GetClientPlayer()
        if not player then
            return
        end
        local KungfuT = player.GetAllMountKungfu();
--~         if _G.bClassic then
--~             SendGMCommand("player.UmountKungfu()") --怀旧版需要先卸载才能装备，临时处理，程序已改所以注释
--~         end
        SendGMCommand("player.MountKungfu("..MountKungfu..","..KungfuT[MountKungfu]..")")
    end

    local fnAddWeapon = function()
--~             Output("fnAddWeapon",titemindexTM,titemtypeTM)
        --SendGMCommand("local tWeapon = {18629,366,730,614,4012,5684,484,5183,6693,730,256,9288,10959};for i,j in ipairs(tWeapon) do if player.GetItemAmount(6,j)<1 then player.AddItem(6,j) end end") --获取武器
        if forceID == 7 then
            --SendGMCommand("for i=1,5 do player.AddItem(6,4000);player.AddItem(6,4014); end")
            local function additemTM(index)
                if index > #titemindexTM then
                    return
                end
                SendGMCommand("player.AddItem("..titemtypeTM..","..titemindexTM[index]..")")
                -- GMMgr.DelayCall(300,mountitem,index)
                -- index = index + 1
                -- GMMgr.DelayCall(500,additemTM,index)
                GMMgr.DelayCall(3,mountitem,index)
                index = index + 1
                GMMgr.DelayCall(5,additemTM,index)
            end
            additemTM(1)
        end
    end

    local fnMountMiji = function()
        local player = GetClientPlayer()
        --学习新门派的秘籍
        for i = 1, #RecipeTab do
            SendGMCommand("player.AddSkillRecipe("..RecipeTab[i].RecipeID..","..RecipeTab[i].RecipeLevel..")")
        end
        for i = 1, #RecipeTab do
            player.ActiveSkillRecipe(RecipeTab[i].RecipeID, RecipeTab[i].RecipeLevel)
            --GetClientPlayer().DeactiveSKillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
        end
    end

    -- local AutoEquipItem = function(MountKungfu,nMapType)
    --     local tKungfu2Index = { --对应无名剑上的序号
    --     [10062] = 0, --铁牢
    --     [10028] = 1, --离经
    --     [10080] = 2, --云裳
    --     [10014] = 3, --紫霞
    --     [10015] = 4, --太虚
    --     [10002] = 5, --洗髓
    --     [10026] = 6, --傲血
    --     [10003] = 7, --易经
    --     [10081] = 8, --冰心
    --     [10021] = 9, --花间
    --     }
    --     SendGMCommand("player.SetCustomInteger1(92, "..nMapType..")") --nMapType 1是10人本，2是25人本，3是5人本
    --     SendGMCommand("player.SetTimer(2 * GLOBAL.GAME_FPS, 'scripts/skill/test/item/无名剑二代.lua', "..(tKungfu2Index[MountKungfu] + 1)..", 0)")
    --     GMMgr.DelayCall(3,fnMountKungfu)
    -- end

    -- local chooseMapType = function(MountKungfu)
    --     -- 端游逻辑要改手游, 先暂时屏蔽
    --     --MessageBox({szMessage="请选择装备强度:",szName="RaidMapBox",fnAutoClose=function() end,{szOption = "10团本", fnAction = function() AutoEquipItem(MountKungfu,1) end},{szOption = "25团本",fnAction = function() AutoEquipItem(MountKungfu,2) end}})
    --     -- local szMessage = "请选择装备强度"

    --     -- local funcConfirm = function ()
    --     --     DeleteAllItem()
    --     -- end
    --     -- local funcCancel = function ()

    --     -- end
    --     -- UIHelper.ShowConfirm(szMessage, funcConfirm)
    -- end

    local fnAddEquip = function()
        if not _G.bClassic then
            -- 端游逻辑要改手游, 先暂时屏蔽
            NewRoleEquipConfig(MountKungfu) --暂时屏蔽怀旧版的角色装备配置

            local tForce2KZSkill = { --空战技能遗忘
            [3]=19989, --天策
            [4]=20012, --纯阳
            [8]=20569, --藏剑
            [10]=20619, --明教
            [2]=20628, --万花
            [1]=20649, --少林
            [5]=20652, --七秀
            [6]=20655, --五毒
            [22]=20658, --长歌
            [21]=20663, --苍云
            [7]=20666, --唐门
            [9]=20670, --丐帮
            [23]=20672, --霸刀
            [24]=20675, --蓬莱
            [25]=23039, --凌雪阁
            }
            for forcenow,skillnow in pairs(tForce2KZSkill) do
                if skillnow ~= tForce2KZSkill[forceID] then
                    SendGMCommand("if player.GetSkillLevel("..skillnow..")~= 0 then player.ForgetSkill("..skillnow..") end") --设置门派
                end
            end
        -- else
        --     OutputMessage("MSG_SYS","未配置怀旧版装备和附魔等信息，屏蔽插件穿装备功能!启用无名剑方式解决！\n")
            -- 端游逻辑要改手游, 先暂时屏蔽
            -- MessageBox({szMessage="请选择副本类型:",szName="ChooseMapBox",fnAutoClose=function() end,{szOption = "团本", fnAction = function() chooseMapType(MountKungfu) end},{szOption = "小本!",fnAction = function() AutoEquipItem(MountKungfu,3) end}})
        end
    end

    -- 这里端游的延时逻辑改为使用Timer实现
    GMMgr.DelayCall(1,fnLevelup)
    GMMgr.DelayCall(2,fnLearnSkill)
    if not _G.bClassic then
        GMMgr.DelayCall(5,fnMountKungfu) --延时1秒执行SaveBodyPart函数
    end
    GMMgr.DelayCall(5,fnAddWeapon) --延时1秒执行SaveBodyPart函数
    GMMgr.DelayCall(4,fnMountMiji) --延时
    GMMgr.DelayCall(4,fnAddEquip) --延时
end

function GetCallBackFun()
    return function(...)
        Output("3D坐标",...)
    end
end

function Goto(x,y,z)
    Output(x,y,z)
    SendGMCommand("player.SetPosition("..x..","..y..","..z..")") --传送过去
end
-- / PostThreadCall(GetCallBackFun(), nil, 'Scene_ScenePositionToGameWorldPosition',1,1,1); --"[输出] 3D坐标换算逻辑坐标"

function SendGCCommand(szCmd)
    SendGMCommand(string.format("GCCommand([[%s]])", szCmd))
end

function DisbandSelfTong()
    local name = GetTongClient().szTongName
    local szCmd = string.format('DisbandTong("%s")', name)
    SendGCCommand(szCmd)
end

function FullfillItem(bNeed)
    if bNeed == 1 then
        SendGMCommand('player.GetScene().CreateNpc(1494, player.nX, player.nY, player.nZ, 0,-1)')
    end

    for i = 1,20 do
        local itemindex
        if math.random(1,10000) > 5000 then
            itemindex = math.random(201,221)
        else
            itemindex = math.random(254,275)
        end
        SendGMCommand('player.AddItem(5,' .. itemindex ..' ,10 )')
    end
end

function GetBuffList(obj) --以前的接口GetBuffList被和谐了，据说是为了提升效率
    if not obj then
        return
    end
    local tbuff = {}
    local nBuffCount = obj.GetBuffCount()
    if nBuffCount and nBuffCount > 0 then
        local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid
        for i = 1, nBuffCount, 1 do
            dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
            table.insert(tbuff,{['dwID'] = dwID,['nLevel'] = nLevel,['bCanCancel'] = bCanCancel,['nEndFrame'] = nEndFrame,['nIndex'] = nIndex,['nStackNum'] = nStackNum,['dwSkillSrcID'] = dwSkillSrcID,['bValid'] = bValid})
        end
    end
    return tbuff
end

function GetBuffList_GetSelectCharacter()
    -- if SearchBuff and #SearchBuff.tTabBase == 0 then
    if SearchBuff and not next(SearchBuff.tBuff) then
        if GMMgr then
            -- GMMgr.Buff_Load() --在这里加载，或者在打开窗口时加载
            -- SearchBuff.tTabBase = g_tTable.Buff
            SearchBuff.FillAll()
        end
    end
    if not _G.nMaxBuffID then
        if SearchBuff then
            -- _G.nMaxBuffID = SearchBuff.tTabBase[#SearchBuff.tTabBase]["ID"]
            _G.nMaxBuffID = SearchBuff.tBuff[#SearchBuff.tBuff]["ID"]

--~                 Output(_G.nMaxBuffID)
        end
    end

    local GMStr = ""..
    "local t = player.GetSelectCharacter()".."\n"..
    "if t then".."\n"..
        "if not IsPlayer(t.dwID) then".."\n"..
            "player.SendSystemMessage('--模板ID:'..t.dwTemplateID..',别名:'..t.szName..',逻辑ID:'..t.dwID..'--')".."\n"..
        "else".."\n"..
            "player.SendSystemMessage('--玩家名字:'..t.szName..',逻辑ID:'..t.dwID..'--')".."\n"..
        "end".."\n"..
        "for i = 1,".._G.nMaxBuffID.." do".."\n"..
            "local b1 = t.GetBuff(i,0)".."\n"..
            "if b1 then".."\n"..
                "local s1 = 'ID：'..b1['dwID']..',nLevel：'..b1['nLevel']..',nStackNum：'..b1['nStackNum']..',nIndex：'..b1['nIndex']".."\n"..
                "player.SendSystemMessage(s1)".."\n"..
            "end".."\n"..
        "end".."\n"..
    "end"
    SendGMCommand(UIHelper.UTF8ToGBK(GMStr))
end

function DestroyAllZTJ()
    --破坏据点里所有状态机
    local lifestr = "npc_State.".._G.CurLife.." = npc_State.".._G.MaxLife.."*0.09\n"
    local lifestr2 = "npc_State.SetCustomUnsigned4(5, npc_State.".._G.MaxLife.."*0.09)\n"

    local GMStr = ""..
        "local scene=player.GetScene()".."\n"..
        "for nCastleIndex = 1, 2 do".."\n"..
            "local npc=scene.GetNpcByNickName('CastleFight'..scene.dwMapID..nCastleIndex)".."\n"..
            "if npc then".."\n"..
                "local nEntityNum = npc.GetCustomUnsigned2(2)".."\n"..
                    "for i = 1, nEntityNum do".."\n"..
                        "local szName = 'CastleStateData' .. nCastleIndex .. i".."\n"..
                        "local npc_StateData = scene.GetNpcByNickName(szName)".."\n"..
                        "if npc_StateData then".."\n"..
                            "local nType = npc_StateData.GetCustomInteger1(25)".."\n"..
                            "local dwStateID = npc_StateData.GetCustomUnsigned4(5)".."\n"..
                          --  if nType == 2 then
                                "local npc_State = GetNpc(dwStateID)".."\n"..
                                "if npc_State then".."\n"..
                                    lifestr..
                                    lifestr2..
                                   -- player.SendSystemMessage(dwStateID .. " oper door")
                                "end".."\n"..
                            --end
                        "end".."\n"..
                    "end".."\n"..
                    "player.SendSystemMessage('据点 ' ..nCastleIndex .. ' 状态机破坏（门和兽栏除外）')".."\n"..
            "end".."\n"..
        "end"
    SendGMCommand(GMStr)
end

function FixAllZTJ()
    local lifestr = "npc_State.".._G.CurLife.." = npc_State.".._G.MaxLife.."\n"
    local lifestr2 = "npc_State.SetCustomUnsigned4(5, npc_State.".._G.MaxLife..")\n"

    local GMStr = ""..
        --恢复据点里所有状态机
        "local scene=player.GetScene()".."\n"..
        "for nCastleIndex = 1, 2 do".."\n"..
            "local npc=scene.GetNpcByNickName('CastleFight'..scene.dwMapID..nCastleIndex)".."\n"..
            "if npc then".."\n"..
                "local nEntityNum = npc.GetCustomUnsigned2(2)".."\n"..
                    "for i = 1, nEntityNum do".."\n"..
                        "local szName = 'CastleStateData' .. nCastleIndex .. i".."\n"..
                        "local npc_StateData = scene.GetNpcByNickName(szName)".."\n"..
                        "if npc_StateData then".."\n"..
                            "local nType = npc_StateData.GetCustomInteger1(25)".."\n"..
                            "local dwStateID = npc_StateData.GetCustomUnsigned4(5)".."\n"..
                          --  if nType == 2 then
                                "local npc_State = GetNpc(dwStateID)".."\n"..
                                "if npc_State then".."\n"..
                                    lifestr..
                                    lifestr2..
                                   -- player.SendSystemMessage(dwStateID .. " oper door")
                                "end".."\n"..
                            --end
                        "end".."\n"..
                    "end".."\n"..
                "player.SendSystemMessage('据点 ' ..nCastleIndex .. ' 状态机恢复')".."\n"..
            "end".."\n"..
        "end"
    SendGMCommand(GMStr)
end

-- 复制文件
local function copyFile(szSrc, szDst)
    local inFile = io.open(szSrc, 'rb')
    if not inFile then
        return
    end

    local data = inFile:read('*a')
    inFile:close();

    local outFile = io.open(szDst, 'wb')
    if not outFile then
        return
    end

    outFile:write(data)
    outFile:close()
    return true
end

-- 将当前使用的UAC复制到临时文件，让角色此新的临时文件
local _nReloadPlayerUACCounter = 1
function ReloadPlayerUAC()
    local player = GetClientPlayer()
    local szPath = Character_GetUAnimatorPath(player.dwID)
    if szPath == nil then
        return
    end

    -- 复制uac文件
    local szUac = string.gsub(szPath, '(%._tmp_[%d]+_)', '')
    local dotPos = string.find(szUac, "%.[^%.]-$")
    local szNewUac = string.format("%s_tmp_%d_%s",
        string.sub(szUac, 1, dotPos),
        _nReloadPlayerUACCounter,
        string.sub(szUac, dotPos)
    )

    if not copyFile(szUac, szNewUac) then
        return
    end

    _nReloadPlayerUACCounter = _nReloadPlayerUACCounter + 1

    -- 复制uab文件
    local szUab = string.format("%suab", string.sub(szUac, 1, dotPos))
    local szNewUab = string.format("%s_tmp_%d_.uab",
        string.sub(szUab, 1, dotPos), _nReloadPlayerUACCounter
    )
    copyFile(szUab, szNewUab)

    -- 重载uac文件
    Character_SetUAnimator(player.dwID, szNewUac, false);

    -- 删除临时文件
    os.remove(szNewUac)
    os.remove(szNewUab)
end

-- 计算ACSII字符宽度
function GMCMD_CalcASCIIWidth()
    local script = UIMgr.GetViewScript(VIEW_ID.PanelGM)
    if script then

        -- Font HYJinKaiJ 26
        local label = script.LabelHYJinKaiJForASCIIWidthCacl
        local szOutput = "Font_HYJinKaiJ_AsciiCharWidth_26 =\n"
        szOutput = szOutput .. "{\n"

        for i = 32, 128 do
            local char = string.char(i)
            UIHelper.SetString(label, char)
            local nW = UIHelper.GetWidth(label)
            szOutput = szOutput .. string.format("\t[%d] = %0.2f, -- %s\n", i, nW, char)
        end

        szOutput = szOutput .. "}\n"

        SetClipboard(szOutput)
        TipsHelper.ShowNormalTip("计算完成，结果已拷贝到剪贴板。")
    end
end

-- 打开关闭UI节点树工具
function GMCMD_OpenNodeExplorer()
    local nViewID = VIEW_ID.PanelNodeExplorer
    local fn = UIMgr.GetView(nViewID) and UIMgr.Close or UIMgr.Open
    fn(nViewID)
end

-- 测试标记开与关
function GMCMD_UpdateCEVerFlag()
    ini = Ini.Open("config.ini")
    ini:WriteInteger("Mobile", "bIsCEVer", Config.bIsCEVer and 0 or 1)
    ini:Save("config.ini")
	ini:Close()

    if Config.bIsCEVer then
        TipsHelper.ShowNormalTip("关闭测试标签")
        Config.bIsCEVer = fasle
    else
        TipsHelper.ShowNormalTip("开启测试标签")
        Config.bIsCEVer = true
    end
end

function GMCMD_AIAgentChatWithNpc(dwNpcTemplateID, szGBKNpcName, szGBKMessage)
    -- 也可以不需要实际的npc实例
    local dwNpcID = 0
    
    LOG.INFO("向AI提问\n dwNpcTemplateID: %d\n szNpcName: %s\n szMessage: %s",
             dwNpcTemplateID, UIHelper.GBKToUTF8(szGBKNpcName), UIHelper.GBKToUTF8(szGBKMessage))

    g_pClientPlayer.AIAgentChat(dwNpcTemplateID, dwNpcID, szGBKNpcName, szGBKMessage)
    TipsHelper.ShowNormalTip("已发起AI对话，请等待10-30秒左右")
end

function GMCMD_AIAgentChatWithSelectedNpc(szGBKMessage)
    -- re: 选中目标后再触发测试
    local eTargetType, dwTargetID = g_pClientPlayer.GetTarget()
    if eTargetType == TARGET.NPC then
        local npc = GetNpc(dwTargetID)
        if npc then
            local dwNpcTemplateID = npc.dwTemplateID
            local dwNpcID         = dwTargetID -- 东方宇轩
            local szGBKNpcName = npc.szName

            LOG.INFO("向AI提问\n dwNpcTemplateID: %d\n dwNpcID: %d\n szNpcName: %s\n szMessage: %s", 
                     dwNpcTemplateID, dwNpcID, UIHelper.GBKToUTF8(szGBKNpcName), UIHelper.GBKToUTF8(szGBKMessage))
            
            g_pClientPlayer.AIAgentChat(dwNpcTemplateID, dwNpcID, szGBKNpcName, szGBKMessage)
            TipsHelper.ShowNormalTip("已发起AI对话，请等待10-30秒左右")
        end
    else
        TipsHelper.ShowNormalTip("请先选中一个NPC作为AI对话对象（可先通过GM指令创建一个NPC并选中，比如东方宇轩）")
    end
end

-- 是否允许Reload判断
function reloadScriptConfirm(fnConfirmCallBack, szText)
    local szIP, szRegion = GetCurrentServerInfo()
    local tbPrivateServer = {
        ["测试"] = true,
        ["策划"] = true,
        ["程序"] = true,
        ["引擎"] = true,
    }
    local tbCMDWhiteList = {
        ["[重载] 重载新手教学"] = true,
    }
    if tbPrivateServer[szRegion] or szIP == "127.0.0.1" or tbCMDWhiteList[szText] then
        fnConfirmCallBack()
    else
        -- 加个账号白名单验证
        if GMMgr.ReloadWhiteList[g_tbLoginData.tbLoginInfo.szLoginAccount] then
            UIHelper.ShowConfirm(string.format('当前服务器为公共服务器, 执行:\n%s会影响他人, 是否确认重载?', szText), fnConfirmCallBack)
        else
            UIHelper.ShowConfirm(string.format("当前服务器为公共服务器, 当前账号:%s\n不允许执行:%s", g_tbLoginData.tbLoginInfo.szLoginAccount, szText))
        end
    end
end

-- 录制角色轨迹
function RecordPos()
    local function rotateAroundY(x, y, z, angle)
        -- 将角度转换为弧度
        local radians = math.rad(angle)

        -- 计算旋转后的坐标
        local cos_a = math.cos(radians)
        local sin_a = math.sin(radians)

        local new_x = x * cos_a + z * sin_a
        local new_y = y -- y 坐标保持不变
        local new_z = -x * sin_a + z * cos_a

        return new_x, new_y, new_z
    end

    if GMMgr.bRecordingPos then
        GMMgr.bRecordingPos = false
        Timer.DelTimer(GMMgr, GMMgr.nPosRecordCallID)

        local offset = #GMMgr.tbPosRecord > 0 and {x = GMMgr.tbPosRecord[1].x, y = GMMgr.tbPosRecord[1].y, z = GMMgr.tbPosRecord[1].z } or {x = 0, y = 0, z = 0}
        for _, pos in ipairs(GMMgr.tbPosRecord) do
            pos.x = pos.x - offset.x
            pos.y = pos.y - offset.y
            pos.z = pos.z - offset.z

            pos.x, pos.y, pos.z = rotateAroundY(pos.x, pos.y, pos.z, -GMMgr.nPosRecordStartDir)
        end

        -- 将位置记录保存到文件
        local filePath = "logs/pos_record_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
        local file = io.open(filePath, "w")
        if file then
            for _, pos in ipairs(GMMgr.tbPosRecord) do
                file:write(string.format("%.3f %.3f %.3f\n", pos.x, pos.y, pos.z))
            end
            file:close()
            LOG.INFO("位置记录已保存到: " .. filePath)
        else
            LOG.ERROR("无法打开文件进行写入: " .. filePath)
        end

        GMMgr.tbPosRecord = nil
        LOG.INFO("停止记录位置")
    else
        GMMgr.bRecordingPos = true
        GMMgr.nPosRecordStartDir = g_pClientPlayer and g_pClientPlayer.nFaceDirection
        GMMgr.tbPosRecord = {}
        LOG.INFO("开始记录位置")

        Timer.DelTimer(GMMgr, GMMgr.nPosRecordCallID)
        GMMgr.nPosRecordCount = 0
        GMMgr.nPosRecordCallID = Timer.AddFrameCycle(GMMgr, 1, function ()
            if GMMgr.tbPosRecord and g_pClientPlayer and GMMgr.nPosRecordCount < 900 then
                table.insert(GMMgr.tbPosRecord, { x = g_pClientPlayer.nX, y = g_pClientPlayer.nY, z = g_pClientPlayer.nZ})
            else
                Timer.DelTimer(GMMgr, GMMgr.nPosRecordCallID)
                GMMgr.nPosRecordCallID = nil
            end
            GMMgr.nPosRecordCount = GMMgr.nPosRecordCount + 1
        end)
    end
end