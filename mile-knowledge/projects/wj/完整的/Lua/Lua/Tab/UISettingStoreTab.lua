UISettingNewStorageTab = {
    Version = {
        [SettingCategory.General] = 1,
        [SettingCategory.Sound] = 2,
        [SettingCategory.Operate] = 1,
        [SettingCategory.Display] = 1,
        [SettingCategory.BattleInfo] = 1,
        [SettingCategory.SkillEnhance] = 1,
        [SettingCategory.ShortcutInteraction] = 16,
        [SettingCategory.Focus] = 1,
        [SettingCategory.GamePad] = 1,
        [SettingCategory.GamepadInteraction] = 3,
    },

    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}
UISettingNewStorageTab_Default = clone(UISettingNewStorageTab)
CustomData.Register(CustomDataType.Global, "UISettingNewStorageTab", UISettingNewStorageTab)

UISettingStoreTab = {
    OnLoaded = function(self, tLoad)
        Lib.ShadowCopyTab(tLoad, self)
    end
}

local GameSettingsStores_version = 21
UISettingStoreTab.ShortcutInteraction = clone(UIShortcutInteractionTab)
UISettingStoreTab.GamepadInteraction = clone(UIGamepadInteractionTab)
UISettingStoreTabDefault = clone(UISettingStoreTab)
CustomData.Register(CustomDataType.Global, "GameSettingsStores_" .. GameSettingsStores_version, UISettingStoreTab)
