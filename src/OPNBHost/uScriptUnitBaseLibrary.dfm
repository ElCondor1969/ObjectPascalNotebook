object ScriptUnitBaseLibrary: TScriptUnitBaseLibrary
  OldCreateOrder = True
  Height = 165
  Width = 214
  object dwsUnitLibrary: TdwsUnit
    Arrays = <
      item
        Name = 'TVariantArray'
        DataType = 'variant'
        IsDynamic = True
      end
      item
        Name = 'TIntegerArray'
        DataType = 'integer'
        IsDynamic = True
      end
      item
        Name = 'TStringArray'
        DataType = 'string'
        IsDynamic = True
      end
      item
        Name = 'TFloatArray'
        DataType = 'float'
        IsDynamic = True
      end
      item
        Name = 'TObjectArray'
        DataType = 'TObject'
        IsDynamic = True
      end
      item
        Name = 'TArrayVariantArray'
        DataType = 'TVariantArray'
        IsDynamic = True
      end>
    Classes = <
      item
        Name = 'TConsole'
        IsSealed = True
        Methods = <
          item
            Name = 'WriteLn'
            Parameters = <
              item
                Name = 'P1'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P2'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P3'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P4'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P5'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P6'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P7'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P8'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P9'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P10'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end>
            OnEval = dwsUnitLibraryClassesTConsoleMethodsWriteLnEval
            Kind = mkClassProcedure
          end
          item
            Name = 'Write'
            Parameters = <
              item
                Name = 'P1'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P2'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P3'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P4'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P5'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P6'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P7'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P8'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P9'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end
              item
                Name = 'P10'
                DataType = 'variant'
                HasDefaultValue = True
                DefaultValue = ''
              end>
            OnEval = dwsUnitLibraryClassesTConsoleMethodsWriteEval
            Kind = mkClassProcedure
          end
          item
            Name = 'Clear'
            OnEval = dwsUnitLibraryClassesTConsoleMethodsClearEval
            Kind = mkClassProcedure
          end
          item
            Name = 'WriteBlock'
            Parameters = <
              item
                Name = 'Text'
                DataType = 'string'
              end
              item
                Name = 'IDBlockRef'
                DataType = 'string'
                HasDefaultValue = True
                DefaultValue = #39#39
              end
              item
                Name = 'Position'
                DataType = 'TConsoleOutputBlockPosition'
                HasDefaultValue = True
                DefaultValue = 0
              end>
            ResultType = 'string'
            OnEval = dwsUnitLibraryClassesTConsoleMethodsWriteBlockEval
            Kind = mkClassFunction
          end
          item
            Name = 'DeleteBlock'
            Parameters = <
              item
                Name = 'IDBlock'
                DataType = 'string'
              end>
            OnEval = dwsUnitLibraryClassesTConsoleMethodsDeleteBlockEval
            Kind = mkClassProcedure
          end>
      end>
    Enumerations = <
      item
        Name = 'TConsoleOutputBlockPosition'
        Elements = <
          item
            Name = 'bpAdd'
          end
          item
            Name = 'bpReplace'
          end
          item
            Name = 'bpDelete'
          end
          item
            Name = 'bpPrior'
          end
          item
            Name = 'bpNext'
          end>
      end>
    Functions = <
      item
        Name = '__DestroyObject'
        Parameters = <
          item
            Name = 'ObjectHandle'
            DataType = 'integer'
          end>
        OnEval = dwsUnitLibraryFunctions__DestroyObjectEval
      end
      item
        Name = '__ArrayToVariant'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'TVariantArray'
          end>
        ResultType = 'variant'
        OnEval = dwsUnitLibraryFunctions__ArrayToVariantEval
      end
      item
        Name = '__ArrayVariantArrayToVariantArray'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'TArrayVariantArray'
            IsWritable = False
          end>
        ResultType = 'TVariantArray'
        OnEval = dwsUnitLibraryFunctions__ArrayVariantArrayToVariantArrayEval
      end
      item
        Name = '__VariantToArray'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'variant'
          end>
        ResultType = 'TVariantArray'
        OnEval = dwsUnitLibraryFunctions__VariantToArrayEval
      end
      item
        Name = '__LibInterface_InvokeLibProc'
        Parameters = <
          item
            Name = 'LibGUID'
            DataType = 'string'
          end
          item
            Name = 'Instance'
            DataType = 'integer'
          end
          item
            Name = 'ProcName'
            DataType = 'string'
          end
          item
            Name = 'Args'
            DataType = 'TVariantArray'
            IsVarParam = True
          end>
        ResultType = 'variant'
        OnEval = dwsUnitLibraryFunctions__LibInterface_InvokeLibProcEval
      end
      item
        Name = 'VarToInt'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'variant'
            IsWritable = False
          end>
        ResultType = 'integer'
        OnEval = dwsUnitLibraryFunctionsVarToIntEval
      end
      item
        Name = 'VarToFloat'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'variant'
            IsWritable = False
          end>
        ResultType = 'float'
        OnEval = dwsUnitLibraryFunctionsVarToFloatEval
      end
      item
        Name = 'VarToStr'
        Parameters = <
          item
            Name = 'Value'
            DataType = 'string'
            IsWritable = False
          end>
        ResultType = 'string'
        OnEval = dwsUnitLibraryFunctionsVarToStrEval
      end
      item
        Name = 'RaiseException'
        Parameters = <
          item
            Name = 'AMessage'
            DataType = 'String'
          end>
        Overloaded = True
        OnEval = dwsUnitLibraryFunctionsRaiseException_String_Eval
      end
      item
        Name = 'RaiseException'
        Parameters = <
          item
            Name = 'AMessage'
            DataType = 'String'
          end
          item
            Name = 'Args'
            DataType = 'array of const'
          end>
        Overloaded = True
        OnEval = dwsUnitLibraryFunctionsRaiseException_Args_Eval
      end
      item
        Name = 'Write'
        Parameters = <
          item
            Name = 'P1'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P2'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P3'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P4'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P5'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P6'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P7'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P8'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P9'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P10'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end>
        OnEval = dwsUnitLibraryFunctionsWriteEval
      end
      item
        Name = 'WriteLn'
        Parameters = <
          item
            Name = 'P1'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P2'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P3'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P4'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P5'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P6'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P7'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P8'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P9'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end
          item
            Name = 'P10'
            DataType = 'variant'
            HasDefaultValue = True
            DefaultValue = ''
          end>
        OnEval = dwsUnitLibraryFunctionsWriteLnEval
      end
      item
        Name = 'Restart'
        OnEval = dwsLibreryUnitFunctionsRestartEval
      end
      item
        Name = 'Import'
        Parameters = <
          item
            Name = 'Namespace'
            DataType = 'string'
          end
          item
            Name = 'APath'
            DataType = 'string'
          end>
        Overloaded = True
        OnEval = dwsUnitLibraryFunctionsImport_stringstring_Eval
      end
      item
        Name = 'SetRemoteOPNBHost'
        Parameters = <
          item
            Name = 'URL'
            DataType = 'String'
            IsVarParam = True
            IsWritable = False
          end>
        OnEval = dwsUnitLibraryFunctionsSetRemoteOPNBHostEval
      end>
    UnitName = 'uBaseLibrary'
    StaticSymbols = False
    Left = 88
    Top = 56
  end
end
