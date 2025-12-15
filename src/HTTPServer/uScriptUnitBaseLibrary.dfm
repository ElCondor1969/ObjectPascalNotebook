object ScriptUnitBaseLibrary: TScriptUnitBaseLibrary
  OldCreateOrder = True
  Height = 165
  Width = 214
  object dwsUnitLibrary: TdwsUnit
    Arrays = <
      item
        Name = 'TIntegerArray'
        DataType = 'integer'
        IsDynamic = True
      end
      item
        Name = 'TVariantArray'
        DataType = 'variant'
        IsDynamic = True
      end
      item
        Name = 'TObjectArray'
        DataType = 'TObject'
        IsDynamic = True
      end
      item
        Name = 'TStringArray'
        DataType = 'string'
        IsDynamic = True
      end>
    Classes = <
      item
        Name = 'TDestroyer'
        IsAbstract = True
        OnCleanUp = dwsUnitLibraryClassesTDestroyerCleanUp
      end
      item
        Name = 'TConsole'
        IsSealed = True
        Methods = <
          item
            Name = 'WriteLn'
            Parameters = <
              item
                Name = 'AMessage'
                DataType = 'string'
              end>
            OnEval = dwsUnitLibraryClassesTConsoleMethodsWriteLnEval
            Kind = mkClassProcedure
          end>
      end>
    Functions = <
      item
        Name = '__DestroyObject'
        Parameters = <
          item
            Name = 'HandleOggetto'
            DataType = 'integer'
          end>
        OnEval = dwsUnitLibraryFunctions__DestroyObjectEval
      end
      item
        Name = '__ArrayToVariant'
        Parameters = <
          item
            Name = 'Parametro'
            DataType = 'TVariantArray'
          end>
        ResultType = 'variant'
        OnEval = dwsUnitLibraryFunctions__ArrayToVariantEval
      end
      item
        Name = '__VariantToArray'
        Parameters = <
          item
            Name = 'Parametro'
            DataType = 'variant'
          end>
        ResultType = 'TVariantArray'
        OnEval = dwsUnitLibraryFunctions__VariantToArrayEval
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
        Name = 'WriteLn'
        Parameters = <
          item
            Name = 'P1'
            DataType = 'variant'
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
      end>
    UnitName = 'uBaseLibrary'
    StaticSymbols = False
    Left = 88
    Top = 56
  end
end
