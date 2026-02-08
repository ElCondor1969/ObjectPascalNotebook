object DataModuleWebServer: TDataModuleWebServer
  OldCreateOrder = False
  Height = 208
  Width = 410
  object IdHTTPServer: TIdHTTPServer
    Bindings = <>
    DefaultPort = 8080
    IOHandler = IdOpenSSLIOHandlerServer
    ListenQueue = 50
    TerminateWaitTime = 60000
    ServerSoftware = 'ObjectPascalNotebookHTTPServer'
    OnCommandError = IdHTTPServerCommandError
    OnCommandOther = IdHTTPServerCommandOther
    OnParseAuthentication = IdHTTPServerParseAuthentication
    OnQuerySSLPort = IdHTTPServerQuerySSLPort
    OnCommandGet = IdHTTPServerCommandGet
    Left = 72
    Top = 24
  end
  object IdMessageEncoderMIME: TIdMessageEncoderMIME
    PermissionCode = 660
    Left = 296
    Top = 128
  end
  object IdMessageDecoderMIME: TIdMessageDecoderMIME
    Left = 296
    Top = 32
  end
  object IdOpenSSLIOHandlerServer: TIdOpenSSLIOHandlerServer
    Left = 72
    Top = 128
  end
end
