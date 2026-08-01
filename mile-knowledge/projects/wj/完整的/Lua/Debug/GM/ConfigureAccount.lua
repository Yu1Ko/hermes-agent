if not ConfigureAccount then
    ConfigureAccount = {
        text = '配置新角色',
    }
end

function ConfigureAccount:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(false)
    if not UIMgr.GetView(VIEW_ID.PanelConfigureAccount) then
        UIMgr.Open(VIEW_ID.PanelConfigureAccount, ConfigureAccount)
    end
end

function ConfigureAccount:OnClick(tbGMView)
    ConfigureAccount:ShowSubWindow(tbGMView)
    tbGMView.tbGMPanelRight = ConfigureAccount
end

ConfigureAccount.Config  = {
    {
        szSchool = "配置-少林",
        --szKungFu =
            {
                szName ="心法-洗髓",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(1,100069,0,GMMgr.SearchRecipe(1,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(1,100069,1,GMMgr.SearchRecipe(1,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(1,100069,2,GMMgr.SearchRecipe(1,0)) end}
            },
            {
                szName ="心法-易经",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(1,100053,0,GMMgr.SearchRecipe(1,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(1,100053,1,GMMgr.SearchRecipe(1,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(1,100053,2,GMMgr.SearchRecipe(1,0)) end}
            },
    },
    {
        szSchool="配置-万花",
        --szKungFu =
            {
                szName ="心法-花间",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(2,100408,0,GMMgr.SearchRecipe(2,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(2,100408,1,GMMgr.SearchRecipe(2,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(2,100408,2,GMMgr.SearchRecipe(2,0)) end}
            },
            {
                szName ="心法-离经",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(2,100411,0,GMMgr.SearchRecipe(2,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(2,100411,1,GMMgr.SearchRecipe(2,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(2,100411,2,GMMgr.SearchRecipe(2,0)) end}
            },
    },
    {
        szSchool="配置-天策",
        --szKungFu =
            {
                szName ="心法-傲血",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(3,100406,0,GMMgr.SearchRecipe(3,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(3,100406,1,GMMgr.SearchRecipe(3,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(3,100406,2,GMMgr.SearchRecipe(3,0)) end}
            },
            {
                szName ="心法-铁牢",
                {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(3,100407,0,GMMgr.SearchRecipe(3,0)) end},
                {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(3,100407,1,GMMgr.SearchRecipe(3,0)) end},
                {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(3,100407,2,GMMgr.SearchRecipe(3,0)) end}
            },
    },
    {
        szSchool="配置-纯阳",
        --szKungFu =
        {
            szName ="心法-紫霞",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(4,100398,0,GMMgr.SearchRecipe(4,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(4,100398,1,GMMgr.SearchRecipe(4,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(4,100398,2,GMMgr.SearchRecipe(4,0)) end}
        },
        {
            szName ="心法-太虚",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(4,100389,0,GMMgr.SearchRecipe(4,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(4,100389,1,GMMgr.SearchRecipe(4,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(4,100389,2,GMMgr.SearchRecipe(4,0)) end}
        },
    },
    {
        szSchool="配置-七秀",
        --szKungFu =
        {
            szName ="心法-云裳",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(5,100409,0,GMMgr.SearchRecipe(5,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(5,100409,1,GMMgr.SearchRecipe(5,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(5,100409,2,GMMgr.SearchRecipe(5,0)) end}
        },
        {
            szName ="心法-冰心",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(5,100410,0,GMMgr.SearchRecipe(5,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(5,100410,1,GMMgr.SearchRecipe(5,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(5,100410,2,GMMgr.SearchRecipe(5,0)) end}
        },
    },
    {
        szSchool="配置-五毒",
        --szKungFu =
        {
            szName ="心法-补天",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(6,100655,0,GMMgr.SearchRecipe(6,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(6,100655,1,GMMgr.SearchRecipe(6,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(6,100655,2,GMMgr.SearchRecipe(6,0)) end}
        },
        {
            szName ="心法-毒经",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(6,100654,0,GMMgr.SearchRecipe(6,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(6,100654,1,GMMgr.SearchRecipe(6,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(6,100654,2,GMMgr.SearchRecipe(6,0)) end}
        },
    },
    {
        szSchool="配置-唐门",
        --szKungFu =
        {
            szName ="心法-天罗",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(7,101734,0,GMMgr.SearchRecipe(7,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(7,101734,1,GMMgr.SearchRecipe(7,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(7,101734,2,GMMgr.SearchRecipe(7,0)) end}
        },
        {
            szName ="心法-惊羽",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(7,101716,0,GMMgr.SearchRecipe(7,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(7,101716,1,GMMgr.SearchRecipe(7,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(7,101716,2,GMMgr.SearchRecipe(7,0)) end}
        },
    },
    {
        szSchool="配置-藏剑",
        --szKungFu =
        -- {
        --     szName ="心法-山居",
        --     {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(8,100726,0,GMMgr.SearchRecipe(8,0)) end},
        --     {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(8,100726,1,GMMgr.SearchRecipe(8,0)) end},
        --     {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(8,100726,2,GMMgr.SearchRecipe(8,0)) end}
        -- },
        {
            szName ="心法-问水",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(8,100725,0,GMMgr.SearchRecipe(8,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(8,100725,1,GMMgr.SearchRecipe(8,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(8,100725,2,GMMgr.SearchRecipe(8,0)) end}
        },
    },
    {
        szSchool="配置-丐帮",
        --szKungFu =
        {
            szName ="心法-笑尘",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(9,100651,0,GMMgr.SearchRecipe(9,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(9,100651,1,GMMgr.SearchRecipe(9,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(9,100651,2,GMMgr.SearchRecipe(9,0)) end}
        },
    },
    {
        szSchool="配置-明教",
        --szKungFu =
        {
            szName ="心法-焚影",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(10,100618,0,GMMgr.SearchRecipe(10,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(10,100618,1,GMMgr.SearchRecipe(10,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(10,100618,2,GMMgr.SearchRecipe(10,0)) end}
        },
        {
            szName ="心法-明尊",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(10,100631,0,GMMgr.SearchRecipe(10,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(10,100631,1,GMMgr.SearchRecipe(10,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(10,100631,2,GMMgr.SearchRecipe(10,0)) end}
        },
    },
    {
        szSchool="配置-苍云",
        --szKungFu =
        {
            szName ="心法-铁骨",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(21,101025,0,GMMgr.SearchRecipe(21,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(21,101025,1,GMMgr.SearchRecipe(21,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(21,101025,2,GMMgr.SearchRecipe(21,0)) end}
        },
        {
            szName ="心法-分山",
            {szName="中立（PVE装备）",fnAction=function() ConfigNewRole(21,101024,0,GMMgr.SearchRecipe(21,0)) end},
            {szName="浩气（PVP装备）",fnAction=function() ConfigNewRole(21,101024,1,GMMgr.SearchRecipe(21,0)) end},
            {szName="恶人（PVP装备）",fnAction=function() ConfigNewRole(21,101024,2,GMMgr.SearchRecipe(21,0)) end}
        },
    },
    {
        szSchool="配置-长歌门",
        --szKungFu =
        {
            szName ="心法-莫问",
            {szName="中立",fnAction=function() ConfigNewRole(22,101124,0,GMMgr.SearchRecipe(22,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(22,101124,1,GMMgr.SearchRecipe(22,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(22,101124,2,GMMgr.SearchRecipe(22,0)) end}
        },
        {
            szName ="心法-相知",
            {szName="中立",fnAction=function() ConfigNewRole(22,101125,0,GMMgr.SearchRecipe(22,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(22,101125,1,GMMgr.SearchRecipe(22,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(22,101125,2,GMMgr.SearchRecipe(22,0)) end}
        },
    },
    {
        szSchool="配置-霸刀",
        --szKungFu =
        {
            szName ="心法-北傲决",
            {szName="中立",fnAction=function() ConfigNewRole(23,100994,0,GMMgr.SearchRecipe(23,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(23,100994,1,GMMgr.SearchRecipe(23,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(23,100994,2,GMMgr.SearchRecipe(23,0)) end}
        },
    },
    {
        szSchool="配置-蓬莱",
        --szKungFu =
        {
            szName ="心法-凌海诀",
            {szName="中立",fnAction=function() ConfigNewRole(24,101090,0,GMMgr.SearchRecipe(24,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(24,101090,1,GMMgr.SearchRecipe(24,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(24,101090,2,GMMgr.SearchRecipe(24,0)) end}
        },
    },
    {
        szSchool="配置-凌雪阁",
        --szKungFu =
        {
            szName ="心法-隐龙诀",
            {szName="中立",fnAction=function() ConfigNewRole(25,101173,0,GMMgr.SearchRecipe(25,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(25,101173,1,GMMgr.SearchRecipe(25,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(25,101173,2,GMMgr.SearchRecipe(25,0)) end}
        },
    },
    {
        szSchool="配置-衍天宗",
        --szKungFu =
        {
            szName ="心法-太玄经",
            {szName="中立",fnAction=function() ConfigNewRole(211,101450,0,GMMgr.SearchRecipe(211,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(211,101450,1,GMMgr.SearchRecipe(211,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(211,101450,2,GMMgr.SearchRecipe(211,0)) end}
        },
    },
    {
        szSchool="配置-北天药宗",
        --szKungFu =
        {
            szName ="心法-灵素",
            {szName="中立",fnAction=function() ConfigNewRole(212,101374,0,GMMgr.SearchRecipe(212,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(212,101374,1,GMMgr.SearchRecipe(212,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(212,101374,2,GMMgr.SearchRecipe(212,0)) end}
        },
        {
            szName ="心法-无方",
            {szName="中立",fnAction=function() ConfigNewRole(212,101355,0,GMMgr.SearchRecipe(212,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(212,101355,1,GMMgr.SearchRecipe(212,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(212,101355,2,GMMgr.SearchRecipe(212,0)) end}
        },
    },
    {
        szSchool="配置-刀宗",
        --szKungFu =
        {
            szName ="心法-孤峰决",
            {szName="中立",fnAction=function() ConfigNewRole(213,101375,0,GMMgr.SearchRecipe(213,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(213,101375,1,GMMgr.SearchRecipe(213,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(213,101375,2,GMMgr.SearchRecipe(213,0)) end}
        },
    },
    {
        szSchool="配置-万灵山庄",
        --szKungFu =
        {
            szName ="心法-山海心诀",
            {szName="中立",fnAction=function() ConfigNewRole(214,101740,0,GMMgr.SearchRecipe(214,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(214,101740,1,GMMgr.SearchRecipe(214,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(214,101740,2,GMMgr.SearchRecipe(214,0)) end}
        },
    },
    {
        szSchool="配置-大理段氏",
        --szKungFu =
        {
            szName ="心法-周天功",
            {szName="中立",fnAction=function() ConfigNewRole(215,102278,0,GMMgr.SearchRecipe(215,0)) end},
            {szName="浩气",fnAction=function() ConfigNewRole(215,102278,1,GMMgr.SearchRecipe(215,0)) end},
            {szName="恶人",fnAction=function() ConfigNewRole(215,102278,2,GMMgr.SearchRecipe(215,0)) end}
        },
    },
}
