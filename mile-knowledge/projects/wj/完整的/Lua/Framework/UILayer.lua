UILayer = UILayer or {}

-- 层级定义
UILayer.Cache 		= "UICacheLayer"
UILayer.Top 		= "UITopLayer"
UILayer.Web 		= "UIWebLayer"
UILayer.Tips 		= "UITipsLayer"
UILayer.HoverTips 	= "UIHoverTipsLayer"
UILayer.SystemPop	= "UISystemPopLayer" 	-- 系统级别的提示，不会被Loading等遮挡的，非常重要的提示会放在这，比如网络相关等
UILayer.Mask 		= "UIMaskLayer"  		-- 遮罩层，放诸如：PanelSceneSwitcher、 PanelCeAnnouncement
UILayer.Loading 	= "UILoadingLayer"		-- Loading层，过图用的
UILayer.MessageBox 	= "UIMessageBoxLayer"
UILayer.Debug 		= "UIDebugLayer"
UILayer.Guide 		= "UIGuideLayer"
UILayer.Popup 		= "UIPopupLayer"
UILayer.Page 		= "UIPageLayer"
UILayer.Main 		= "UIMainLayer"
UILayer.Battle 		= "UIBattleLayer"
UILayer.Scene 		= "UISceneLayer"

-- 层级的值
UILayer.NameToLayer =
{
	[UILayer.Cache] 		= 150000,
	[UILayer.Top] 			= 140000,
	[UILayer.Web] 			= 130000,
	[UILayer.Tips] 			= 120000,
	[UILayer.HoverTips] 	= 110000,
	[UILayer.SystemPop] 	= 100000,
	[UILayer.Mask] 			= 90000,
	[UILayer.Loading] 		= 80000,
    [UILayer.MessageBox]    = 70000,
	[UILayer.Debug] 		= 60000,
	[UILayer.Guide] 		= 50000,
	[UILayer.Popup]	        = 40000,
	[UILayer.Page]		    = 30000,
	[UILayer.Main]		    = 20000,
	[UILayer.Battle]		= 10000,
	[UILayer.Scene] 		= 0,
}