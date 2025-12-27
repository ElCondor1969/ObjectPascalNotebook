object ScriptExecuter: TScriptExecuter
  OldCreateOrder = False
  Height = 234
  Width = 317
  object DelphiWebScript: TDelphiWebScript
    Config.CompilerOptions = [coOptimize, coAssertions, coAllowClosures, coAllowAsyncAwait]
    Config.OnInclude = DelphiWebScriptInclude
    Config.OnNeedUnit = DelphiWebScriptNeedUnit
    Left = 72
    Top = 40
  end
  inline dwsClassesLib: TdwsClassesLib
    OldCreateOrder = False
    Script = DelphiWebScript
    Left = 72
    Top = 144
    Height = 0
    Width = 0
  end
  object dwsJSONLibModule: TdwsJSONLibModule
    Script = DelphiWebScript
    Left = 208
    Top = 144
  end
  object dwsRTTIConnector: TdwsRTTIConnector
    Script = DelphiWebScript
    StaticSymbols = False
    Left = 208
    Top = 40
  end
end
