unit Assis.SQLExtractor;

interface

uses Assis.RttiInterceptor;  ///https://github.com/ricardodarocha/Rtti

type

  {$REGION 'Anotations'}
  KeyAttribute = class(TCustomAttribute)
    fCampoChave: String;
    constructor Create(aCampoChave: String = 'CODIGO');
  end;

  AutoincrementAttribute = class(TCustomAttribute)
  end;

  TamanhoAttribute = class(TCustomAttribute)
    fSize: String;
    constructor Create(aSize: integer = 255);
  end;

  PrecisionAttribute = class(TCustomAttribute)
    fSize: String;
    fDecimals: String;
    constructor Create(aSize: integer = 16; aDecimals: integer = 4);
  end;

  TablenameAttribute = class(TCustomAttribute)
    fNomeTabela: String;
    constructor Create(aNomeTabela: String);
  end;

  UniqueAttribute = class(TCustomAttribute)
    fUniqueCampos: String;
    constructor Create(aCampos: String);
  end;

  NotnullAttribute = class(TCustomAttribute)
  end;

  ForeignKeyAttribute = class(TCustomAttribute)
    fForeignKeyCampo: String;
    constructor Create(aCampo: String = '');
  end;

  LookupAttribute = class(TCustomAttribute)
    fLookupCampo: String;
    constructor Create(aCampo: String);  //Campo da tabela ligada que será retornado, exemplo TCategoria.NOME
  end;
  {$ENDREGION}

  {$REGION 'Sql Stypes'}
   { Declare the name of type as you want to generate the Create Table SQL }
   VARCHAR = type string;
   NUMERIC = type Extended;
   DECIMAL = type Double;

  {$ENDREGION}

  /// <summary>
  /// Implementa métodos para extrair sql automáticos de qualquer objeto
  ///  <code>strTablename := TSqlExtrator<TPedido>.ExtractTablename(vPedido, 'TAB_')</code>
  ///  strSelect := TSqlExtrator<TPedido>.ExtractSelectSql(vPedido)
  ///  strUpdateSql := TSqlExtrator<TPedido>.ExtractUpdateSql(vPedido)
  ///  strInnerJoinSql := TSqlExtrator<TPedido>.ExtractInnerJoin(vPedido)
  /// </summary>
  TSqlExtractor<T: Class> = class
  private
    class function Join(aArray: TArray<String>; aJoining: String = ', '): String;
    class function GetParamNames(aClass: T): TArray<string>;
    class function GetFieldnamesTypes(aClass: T): TArray<string>;
    class function GetFieldnames(aClass: T): TArray<string>;
    class function GetLookupFieldnames(aClass: T): TArray<string>;
  public
    class function ExtractTablename(aClass: T; aPrefix: String = ''): String;
    class function ExtractKeyFields(aClass: T; aKeyFields: TArray<String> = []): TArray<String>;
    class function ExtractCreateTableSql(aClass: T): String;
    class function ExtractSelectSql(aClass: T; aFilter: TArray<String> = []): String;
    class function ExtractInsertIntoSql(aClass: T): String;
    class function ExtractUpdateSql(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractDeleteSql(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractWhere(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractInnerJoin(aClass: T): TArray<string>;
  end;

implementation

uses
  System.SysUtils, System.Rtti, System.Contnrs;

{ TSqlExtrator<T> }

class function TSqlExtractor<T>.ExtractCreateTableSql(aClass: T): String;
begin
  result := format('CREATE TABLE %s (%s)', [ ExtractTableName(aClass) , Join(GetFieldnamesTypes(aClass), ', '#13#10)]);
end;

class function TSqlExtractor<T>.ExtractTablename(aClass: T; aPrefix: String): String;
begin
  result := aClass.ClassName;

  if length(result) > 0 then
    if result[1] = 'T' then
      delete(result, 1,1);

  result := aPrefix + result;
end;

class function TSqlExtractor<T>.ExtractKeyFields(aClass: T; aKeyFields: TArray<String>): TArray<String>;
var
  aValue: String;
begin
  aValue := '';
  result := aKeyFields;
  if length(result) = 0 then
  begin
    TRttiInterceptor<T>.Mapfield(aClass, procedure (aField: TRttiField)
                     begin
                      if aValue = '' then
                         aValue := format('%s', [aField.Name])
                      else
                       exit;
                     end);
    SetLength(result, 1);
    result[0] := aValue;
  end;
end;

class function TSqlExtractor<T>.ExtractDeleteSql(aClass: T; aKeyFields: TArray<String>): String;
  var
    vWhere : String;
begin

  if length(aKeyFields) = 0 then
    aKeyFields := ExtractKeyFields(aClass, aKeyFields);

  vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aKeyFields);
  result := format('DELETE FROM %s where (%s)', [ExtractTableName(aClass), vWhere]); // (codigo = :codigo) and (empresa = :empresa)
end;

class function TSqlExtractor<T>.ExtractInnerJoin(aClass: T): TArray<string>;

  var
    vFieldNames: TArray<String>;
    vTeste: TObject;
    vSubtipo: String;
    vReferencedField: String;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)

                    var
                     vClassType: TClass;
                     vAttr: TCustomAttribute;
                     vTabelaEstrangeira: String;
                     vI: Integer;
                     begin
                       for vAttr in aField.GetAttributes do
                         if vAttr is ForeignKeyAttribute then
                          vReferencedField := ForeignKeyAttribute(vAttr).fForeignKeyCampo;
                       if vReferencedField = '' then
                         vReferencedField := 'CODIGO';

                       if ((aField.FieldType.TypeKind)=tkClass) and (aField.FieldType.ToString.StartsWith ('TObjectList<')) then
                       begin
                         SetLength(vFieldNames, length(vFieldNames) + 1);
                         vTabelaEstrangeira := aField.FieldType.Name;
                         Delete(vTabelaEstrangeira, 1, length('TObjectList<'));
                         Delete(vTabelaEstrangeira, length(vTabelaEstrangeira), 1);
                         for vI := length(vTabelaEstrangeira) downto 1 do
                         if vTabelaEstrangeira[vI] = '.' then
                         begin
                           delete(vTabelaEstrangeira,1, vI);
                           break;
                         end;

                         vTabelaEstrangeira := vTabelaEstrangeira + ' as ' + aField.Name;

                         delete(vTabelaEstrangeira,1,1);
                         vFieldNames[high(vFieldNames)] := format('INNER JOIN %s on %s.%s = %s.%s', [vTabelaEstrangeira, aField.Name, vReferencedField, ExtractTableName(aClass), aField.Name]);


                       end else

                       if (aField.FieldType.TypeKind)=tkClass then
                       begin
                         SetLength(vFieldNames, length(vFieldNames) + 1);
                         vTabelaEstrangeira := aField.FieldType.Name + ' as ' + aField.Name;
                         delete(vTabelaEstrangeira,1,1);
                         vFieldNames[high(vFieldNames)] := format('INNER JOIN %s on %s.%s = %s.%s', [vTabelaEstrangeira, aField.Name, vReferencedField, ExtractTableName(aClass), aField.Name]);

                         if not aField.GetValue(Pointer(aClass)).IsEmpty then
                         begin
                           vTeste := aField.GetValue(Pointer(aClass)).AsObject;
                           vClassType := vTeste.ClassType;
                         end;
                       end;

                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.ExtractInsertIntoSql(aClass: T): String;
begin
  result := format('INSERT INTO %s (%s) VALUES(%s)', [
    ExtractTableName(aClass),
    Join(GetFieldNames(aClass)),
    Join(GetParamNames(aClass))
    ]); // (codigo, empresa) VALUES (:codigo, :empresa)

end;

class function TSqlExtractor<T>.ExtractSelectSql(aClass: T; aFilter: TArray<String>): String;

var
  vIterator: Integer;
  vWhere: String;
  vCamposLookup: String;
  vCampos: String;
  vInnerJoin: String;
begin
  for vIterator := 0 to Length(aFilter)-1 do
    aFilter[vIterator] := format ('(%s = :%0:s)', [aFilter[vIterator]]); //['codigo = :codigo', 'empresa = :empresa']

  if length(aFilter)>0 then
    vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aFilter);

  if vWhere <> '' then
    vWhere := ' WHERE ' + vWhere
  else
    vwhere := '/* where não informado */';

  vCampos := Join(GetFieldNames(aClass)); //Campo1, Campo2, .. Campon
  if vCampos = '' then
    vCampos := ExtractTableName(aClass) + '.*';

  vCamposLookup := Join(GetLookupFieldnames(aClass)); //Categoria.Nome, Categoria.Empresa

  vInnerJoin := '  ' + Join(TSqlExtractor<T>.ExtractInnerJoin(aClass), ''#13#10'  ');
  if vInnerJoin <> '' then
    vInnerJoin := vInnerJoin + ''#13;

  result := format('select %s %s '#13#10'from %s '#13#10 + '%s %s', [
    vCampos,
    vCamposLookup,
    ExtractTableName(aClass),
    vInnerJoin,
    vWhere]); // select codigo, empresa, produto from produtoempresa /* where não informado */

end;

class function TSqlExtractor<T>.ExtractUpdateSql(aClass: T; aKeyFields: TArray<String>): String;
  var
    vFieldNames: TArray<String>;
    vIterator: Integer;
  vWhere: string;
begin


  vFieldNames := GetFieldnames(aClass);
  for vIterator := 0 to Length(vFieldNames)-1 do
    vFieldNames[vIterator] := format ('%s = :%0:s', [vFieldNames[vIterator]]); // ('codigo = :codigo') AND ('empresa = :empresa')

  vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aKeyFields);

  result := format('update %s set(%s) WHERE %s ', [
    ExtractTableName(aClass),
    Join(vFieldNames ),
    vWhere]); // (codigo = :codigo) and (empresa = :empresa)

  if Length(vWhere) = 0 then
    raise Exception.Create('Atenção UPDATE não encontrou cláusula WHERE '#13 + result);

end;

class function TSqlExtractor<T>.ExtractWhere(aClass: T; aKeyFields: TArray<String>): String;
var
  vIterator: Integer;
begin
  {Identifica as chaves}
  aKeyFields := ExtractKeyFields(aClass, aKeyFields);

  for vIterator := 0 to Length(aKeyFields)-1 do
    if (pos(' ',  trim(aKeyFields[vIterator])) = 0)
    and (pos('=',  aKeyFields[vIterator]) = 0)
    and (pos('>',  aKeyFields[vIterator]) = 0)
    and (pos('<',  aKeyFields[vIterator]) = 0)
    and (pos(' not in',  aKeyFields[vIterator]) = 0)
    and (pos(' between',  aKeyFields[vIterator]) = 0) then
    aKeyFields[vIterator] := format ('(%s = :%0:s)', [aKeyFields[vIterator]]); //['codigo = :codigo', 'empresa = :empresa']

  result := trim(Join(aKeyFields, ' AND '));
end;

class function TSqlExtractor<T>.GetFieldnamesTypes(aClass: T): TArray<string>;

  var
    vFieldNames: TArray<String>;
    vTeste: TObject;
    vSubtipo: String;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     var
                     vClassType: TClass;
                     vAttr: TCustomAttribute;

                     vNotnull: String;
                     vPrimaryKey: String;
                     vReferences: String;
                     vPrecision: String;
                     vSentence: String;
                     vReferencedField: String;
                     begin
                       vNotNull := '';
                       vReferences := '';
                       vPrimaryKey := '';
                       vPrecision := '';
                       vSentence := '';
                       vReferencedField := '';

                       for vAttr in aField.GetAttributes do
                       begin
                         if vAttr is NotNullAttribute then
                            vNotNull := 'NOT NULL'

                         else if vAttr is KeyAttribute then
                            vPrimaryKey := 'PRIMARY KEY ' + vPrimaryKey

                         else if vAttr is AutoincrementAttribute then
                            vPrimaryKey := vPrimaryKey + ' AUTOINCREMENT'

                         else if vAttr is TamanhoAttribute then
                            vPrecision := '(' + TamanhoAttribute(vAttr).fSize + ')'

                         else if vAttr is PrecisionAttribute then
                          with PrecisionAttribute(vAttr) do vPrecision := format('(%s,%s)', [fSize, fDecimals])

                         else if vAttr is ForeignKeyAttribute then
                          vReferencedField := ForeignKeyAttribute(vAttr).fForeignKeyCampo;

                       end;

                       if vPrecision = '' then
                       begin
                         if LowerCase(aField.FieldType.Name)='numeric' then
                           vPrecision := '(15,6)'
                         else if LowerCase(aField.FieldType.Name)='currency' then
                           vPrecision :=  '(15,4)';
                       end;

                       vSentence := format('%s %s %s', [aField.Name, UPPERCASE(aField.FieldType.Name) + vPrecision, vNotNull]);

                       if (aField.FieldType.TypeKind)=tkClass then
                       begin
                        if vReferencedField = ''  then
                          vReferencedField := 'CODIGO';

                         vSentence := format('%s %s %s', [aField.Name, 'INTEGER', vNotNull]);
                         vReferences := format(' REFERENCES %s(%s)', [aField.FieldType.Name, vReferencedField]);
                         delete(vReferences, 13, 1);
                         if not aField.GetValue(Pointer(aClass)).IsEmpty then
                         begin
                           vTeste := aField.GetValue(Pointer(aClass)).AsObject;
                           vClassType := vTeste.ClassType;
                         end;
                       end;

                       SetLength(vFieldNames, length(vFieldNames) + 1);
                       vFieldNames[high(vFieldNames)] := trim(format('%s %s %s', [vSentence, vPrimaryKey, vReferences]));


                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.GetLookupFieldnames(aClass: T): TArray<string>;
  var vFieldNames: TArray<String>;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     var
                      vAttr: TCustomAttribute;
                      vFieldTemp: String;
                     begin
                      for vAttr in aField.GetAttributes do
                      begin
                          if vAttr is LookupAttribute then
                          begin
                            SetLength(vFieldNames, length(vFieldNames) + 1);
                            vFieldTemp := aField.FieldType.Name;
                            delete(vFieldTemp, 1,1 );
                            vFieldTemp := StringReplace(vFieldTemp + '.' + LookupAttribute(vAttr).fLookupCampo, ',', ',' + vFieldTemp+ '.'  , [rfReplaceAll]);  //Categoria.Codigo, Categoria.Empresa

                            setLength(vFieldNames, length(vFieldNames)+1);
                            vFieldNames[high(vFieldNames)] := vFieldTemp;
                          end;

                      end;
                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.GetParamNames(aClass: T): TArray<string>;
  var
    vIterator: Integer;
begin
  Result := TSqlExtractor<T>.GetFieldnames(aClass);
  for vIterator := 0 to Length(Result) do
    Result[vIterator] := ':' + Result[vIterator];

end;

class function TSqlExtractor<T>.GetFieldnames(aClass: T): TArray<string>;
  var vFieldNames: TArray<String>;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     begin
                      SetLength(vFieldNames, length(vFieldNames) + 1);
                      vFieldNames[high(vFieldNames)] := ExtractTablename(aClass) + '.' + aField.Name;
                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.Join(aArray: TArray<String>; aJoining: String): String;
var
  i : Integer;
begin
  Result := '';
  for i := low(aArray) to high(aArray) do
    Result := Result + aArray[i] + aJoining;

  for I := 1 to length(aJoining) do
    Delete(Result, Length(Result), 1);
end;

{ TSizeAttribute }

constructor TamanhoAttribute.Create(aSize: integer);
begin
  fSize := aSize.ToString;
end;

{ TPrecision }

constructor PrecisionAttribute.Create(aSize, aDecimals: integer);
begin
  fSize := aSize.ToString;
  fDecimals := aDecimals.ToString;
end;

{ TKeyAttribute }

constructor KeyAttribute.Create(aCampoChave: String);
begin
  fCampoChave := aCampoChave;
end;

{ TTablenameAttribute }

constructor TablenameAttribute.Create(aNomeTabela: String);
begin
  fNomeTabela := aNomeTabela
end;

{ TUniqueAttribute }

constructor UniqueAttribute.Create(aCampos: String);
begin
  fUniqueCampos := aCampos;
end;

{ TForeignKeyAttribute }

constructor ForeignKeyAttribute.Create(aCampo: String);
begin
  fForeignKeyCampo := aCampo;
end;

{ TLookupAttribute }

constructor LookupAttribute.Create(aCampo: String);
begin
  fLookupCampo := aCampo;
end;

end.
=======
unit Assis.SQLExtractor;

interface

uses Assis.RttiInterceptor;  ///https://github.com/ricardodarocha/RttiInterceptor

type

  {$REGION 'Anotations'}
  KeyAttribute = class(TCustomAttribute)
    fCampoChave: String;
    constructor Create(aCampoChave: String = 'CODIGO');
  end;

  AutoincrementAttribute = class(TCustomAttribute)
  end;

  TamanhoAttribute = class(TCustomAttribute)
    fSize: String;
    constructor Create(aSize: integer = 255);
  end;

  PrecisionAttribute = class(TCustomAttribute)
    fSize: String;
    fDecimals: String;
    constructor Create(aSize: integer = 16; aDecimals: integer = 4);
  end;

  TablenameAttribute = class(TCustomAttribute)
    fNomeTabela: String;
    constructor Create(aNomeTabela: String);
  end;

  UniqueAttribute = class(TCustomAttribute)
    fUniqueCampos: String;
    constructor Create(aCampos: String);
  end;

  NotnullAttribute = class(TCustomAttribute)
  end;

  ForeignKeyAttribute = class(TCustomAttribute)
    fForeignKeyCampo: String;
    constructor Create(aCampo: String = '');
  end;

  LookupAttribute = class(TCustomAttribute)
    fLookupCampo: String;
    constructor Create(aCampo: String);  //Campo da tabela ligada que será retornado, exemplo TCategoria.NOME
  end;
  {$ENDREGION}

  /// <summary>
  /// Implementa métodos para extrair sql automáticos de qualquer objeto
  ///  <code>strTablename := TSqlExtrator<TPedido>.ExtractTablename(vPedido, 'TAB_')</code>
  ///  strSelect := TSqlExtrator<TPedido>.ExtractSelectSql(vPedido)
  ///  strUpdateSql := TSqlExtrator<TPedido>.ExtractUpdateSql(vPedido)
  ///  strInnerJoinSql := TSqlExtrator<TPedido>.ExtractInnerJoin(vPedido)
  /// </summary>
  TSqlExtractor<T: Class> = class
  private
    class function Join(aArray: TArray<String>; aJoining: String = ', '): String;
    class function GetParamNames(aClass: T): TArray<string>;
    class function GetFieldnamesTypes(aClass: T): TArray<string>;
    class function GetFieldnames(aClass: T): TArray<string>;
    class function GetLookupFieldnames(aClass: T): TArray<string>;
  public
    class function ExtractTablename(aClass: T; aPrefix: String = ''): String;
    class function ExtractKeyFields(aClass: T; aKeyFields: TArray<String> = []): TArray<String>;
    class function ExtractCreateTableSql(aClass: T): String;
    class function ExtractSelectSql(aClass: T; aFilter: TArray<String> = []): String;
    class function ExtractInsertIntoSql(aClass: T): String;
    class function ExtractUpdateSql(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractDeleteSql(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractWhere(aClass: T; aKeyFields: TArray<String> = []): String;
    class function ExtractInnerJoin(aClass: T): TArray<string>;
  end;

implementation

uses
  System.SysUtils, System.Rtti, System.Contnrs;

{ TSqlExtrator<T> }

class function TSqlExtractor<T>.ExtractCreateTableSql(aClass: T): String;
begin
  result := format('CREATE TABLE %s (%s)', [ ExtractTableName(aClass) , Join(GetFieldnamesTypes(aClass), ', '#13#10)]);
end;

class function TSqlExtractor<T>.ExtractTablename(aClass: T; aPrefix: String): String;
begin
  result := aClass.ClassName;

  if length(result) > 0 then
    if result[1] = 'T' then
      delete(result, 1,1);

  result := aPrefix + result;
end;

class function TSqlExtractor<T>.ExtractKeyFields(aClass: T; aKeyFields: TArray<String>): TArray<String>;
var
  aValue: String;
begin
  aValue := '';
  result := aKeyFields;
  if length(result) = 0 then
  begin
    TRttiInterceptor<T>.Mapfield(aClass, procedure (aField: TRttiField)
                     begin
                      if aValue = '' then
                         aValue := format('%s', [aField.Name])
                      else
                       exit;
                     end);
    SetLength(result, 1);
    result[0] := aValue;
  end;
end;

class function TSqlExtractor<T>.ExtractDeleteSql(aClass: T; aKeyFields: TArray<String>): String;
  var
    vWhere : String;
begin

  if length(aKeyFields) = 0 then
    aKeyFields := ExtractKeyFields(aClass, aKeyFields);

  vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aKeyFields);
  result := format('DELETE FROM %s where (%s)', [ExtractTableName(aClass), vWhere]); // (codigo = :codigo) and (empresa = :empresa)
end;

class function TSqlExtractor<T>.ExtractInnerJoin(aClass: T): TArray<string>;

  var
    vFieldNames: TArray<String>;
    vTeste: TObject;
    vSubtipo: String;
    vReferencedField: String;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)

                    var
                     vClassType: TClass;
                     vAttr: TCustomAttribute;
                     vTabelaEstrangeira: String;
                     vI: Integer;
                     begin
                       for vAttr in aField.GetAttributes do
                         if vAttr is ForeignKeyAttribute then
                          vReferencedField := ForeignKeyAttribute(vAttr).fForeignKeyCampo;
                       if vReferencedField = '' then
                         vReferencedField := 'CODIGO';

                       if ((aField.FieldType.TypeKind)=tkClass) and (aField.FieldType.ToString.StartsWith ('TObjectList<')) then
                       begin
                         SetLength(vFieldNames, length(vFieldNames) + 1);
                         vTabelaEstrangeira := aField.FieldType.Name;
                         Delete(vTabelaEstrangeira, 1, length('TObjectList<'));
                         Delete(vTabelaEstrangeira, length(vTabelaEstrangeira), 1);
                         for vI := length(vTabelaEstrangeira) downto 1 do
                         if vTabelaEstrangeira[vI] = '.' then
                         begin
                           delete(vTabelaEstrangeira,1, vI);
                           break;
                         end;

                         vTabelaEstrangeira := vTabelaEstrangeira + ' as ' + aField.Name;

                         delete(vTabelaEstrangeira,1,1);
                         vFieldNames[high(vFieldNames)] := format('INNER JOIN %s on %s.%s = %s.%s', [vTabelaEstrangeira, aField.Name, vReferencedField, ExtractTableName(aClass), aField.Name]);


                       end else

                       if (aField.FieldType.TypeKind)=tkClass then
                       begin
                         SetLength(vFieldNames, length(vFieldNames) + 1);
                         vTabelaEstrangeira := aField.FieldType.Name + ' as ' + aField.Name;
                         delete(vTabelaEstrangeira,1,1);
                         vFieldNames[high(vFieldNames)] := format('INNER JOIN %s on %s.%s = %s.%s', [vTabelaEstrangeira, aField.Name, vReferencedField, ExtractTableName(aClass), aField.Name]);

                         if not aField.GetValue(Pointer(aClass)).IsEmpty then
                         begin
                           vTeste := aField.GetValue(Pointer(aClass)).AsObject;
                           vClassType := vTeste.ClassType;
                         end;
                       end;

                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.ExtractInsertIntoSql(aClass: T): String;
begin
  result := format('INSERT INTO %s (%s) VALUES(%s)', [
    ExtractTableName(aClass),
    Join(GetFieldNames(aClass)),
    Join(GetParamNames(aClass))
    ]); // (codigo, empresa) VALUES (:codigo, :empresa)

end;

class function TSqlExtractor<T>.ExtractSelectSql(aClass: T; aFilter: TArray<String>): String;

var
  vIterator: Integer;
  vWhere: String;
  vCamposLookup: String;
  vCampos: String;
  vInnerJoin: String;
begin
  for vIterator := 0 to Length(aFilter)-1 do
    aFilter[vIterator] := format ('(%s = :%0:s)', [aFilter[vIterator]]); //['codigo = :codigo', 'empresa = :empresa']

  if length(aFilter)>0 then
    vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aFilter);

  if vWhere <> '' then
    vWhere := ' WHERE ' + vWhere
  else
    vwhere := '/* where não informado */';

  vCampos := Join(GetFieldNames(aClass)); //Campo1, Campo2, .. Campon
  if vCampos = '' then
    vCampos := ExtractTableName(aClass) + '.*';

  vCamposLookup := Join(GetLookupFieldnames(aClass)); //Categoria.Nome, Categoria.Empresa

  vInnerJoin := '  ' + Join(TSqlExtractor<T>.ExtractInnerJoin(aClass), ''#13#10'  ');
  if vInnerJoin <> '' then
    vInnerJoin := vInnerJoin + ''#13;

  result := format('select %s %s '#13#10'from %s '#13#10 + '%s %s', [
    vCampos,
    vCamposLookup,
    ExtractTableName(aClass),
    vInnerJoin,
    vWhere]); // select codigo, empresa, produto from produtoempresa /* where não informado */

end;

class function TSqlExtractor<T>.ExtractUpdateSql(aClass: T; aKeyFields: TArray<String>): String;
  var
    vFieldNames: TArray<String>;
    vIterator: Integer;
  vWhere: string;
begin


  vFieldNames := GetFieldnames(aClass);
  for vIterator := 0 to Length(vFieldNames)-1 do
    vFieldNames[vIterator] := format ('%s = :%0:s', [vFieldNames[vIterator]]); // ('codigo = :codigo') AND ('empresa = :empresa')

  vWhere := TSqlExtractor<T>.ExtractWhere(aClass, aKeyFields);

  result := format('update %s set(%s) WHERE %s ', [
    ExtractTableName(aClass),
    Join(vFieldNames ),
    vWhere]); // (codigo = :codigo) and (empresa = :empresa)

  if Length(vWhere) = 0 then
    raise Exception.Create('Atenção UPDATE não encontrou cláusula WHERE '#13 + result);

end;

class function TSqlExtractor<T>.ExtractWhere(aClass: T; aKeyFields: TArray<String>): String;
var
  vIterator: Integer;
begin
  {Identifica as chaves}
  aKeyFields := ExtractKeyFields(aClass, aKeyFields);

  for vIterator := 0 to Length(aKeyFields)-1 do
    if (pos(' ',  trim(aKeyFields[vIterator])) = 0)
    and (pos('=',  aKeyFields[vIterator]) = 0)
    and (pos('>',  aKeyFields[vIterator]) = 0)
    and (pos('<',  aKeyFields[vIterator]) = 0)
    and (pos(' not in',  aKeyFields[vIterator]) = 0)
    and (pos(' between',  aKeyFields[vIterator]) = 0) then
    aKeyFields[vIterator] := format ('(%s = :%0:s)', [aKeyFields[vIterator]]); //['codigo = :codigo', 'empresa = :empresa']

  result := trim(Join(aKeyFields, ' AND '));
end;

class function TSqlExtractor<T>.GetFieldnamesTypes(aClass: T): TArray<string>;

  var
    vFieldNames: TArray<String>;
    vTeste: TObject;
    vSubtipo: String;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     var
                     vClassType: TClass;
                     vAttr: TCustomAttribute;

                     vNotnull: String;
                     vPrimaryKey: String;
                     vReferences: String;
                     vPrecision: String;
                     vSentence: String;
                     vReferencedField: String;
                     begin
                       vNotNull := '';
                       vReferences := '';
                       vPrimaryKey := '';
                       vPrecision := '';
                       vSentence := '';
                       vReferencedField := '';

                       for vAttr in aField.GetAttributes do
                       begin
                         if vAttr is NotNullAttribute then
                            vNotNull := 'NOT NULL'

                         else if vAttr is KeyAttribute then
                            vPrimaryKey := 'PRIMARY KEY ' + vPrimaryKey

                         else if vAttr is AutoincrementAttribute then
                            vPrimaryKey := vPrimaryKey + ' AUTOINCREMENT'

                         else if vAttr is TamanhoAttribute then
                            vPrecision := '(' + TamanhoAttribute(vAttr).fSize + ')'

                         else if vAttr is PrecisionAttribute then
                          with PrecisionAttribute(vAttr) do vPrecision := format('(%s,%s)', [fSize, fDecimals])

                         else if vAttr is ForeignKeyAttribute then
                          vReferencedField := ForeignKeyAttribute(vAttr).fForeignKeyCampo;

                       end;

                       if vPrecision = '' then
                       begin
                         if LowerCase(aField.FieldType.Name)='numeric' then
                           vPrecision := '(15,6)'
                         else if LowerCase(aField.FieldType.Name)='currency' then
                           vPrecision :=  '(15,4)';
                       end;

                       vSentence := format('%s %s %s', [aField.Name, UPPERCASE(aField.FieldType.Name) + vPrecision, vNotNull]);

                       if (aField.FieldType.TypeKind)=tkClass then
                       begin
                        if vReferencedField = ''  then
                          vReferencedField := 'CODIGO';

                         vSentence := format('%s %s %s', [aField.Name, 'INTEGER', vNotNull]);
                         vReferences := format(' REFERENCES %s(%s)', [aField.FieldType.Name, vReferencedField]);
                         delete(vReferences, 13, 1);
                         if not aField.GetValue(Pointer(aClass)).IsEmpty then
                         begin
                           vTeste := aField.GetValue(Pointer(aClass)).AsObject;
                           vClassType := vTeste.ClassType;
                         end;
                       end;

                       SetLength(vFieldNames, length(vFieldNames) + 1);
                       vFieldNames[high(vFieldNames)] := trim(format('%s %s %s', [vSentence, vPrimaryKey, vReferences]));


                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.GetLookupFieldnames(aClass: T): TArray<string>;
  var vFieldNames: TArray<String>;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     var
                      vAttr: TCustomAttribute;
                      vFieldTemp: String;
                     begin
                      for vAttr in aField.GetAttributes do
                      begin
                          if vAttr is LookupAttribute then
                          begin
                            SetLength(vFieldNames, length(vFieldNames) + 1);
                            vFieldTemp := aField.FieldType.Name;
                            delete(vFieldTemp, 1,1 );
                            vFieldTemp := StringReplace(vFieldTemp + '.' + LookupAttribute(vAttr).fLookupCampo, ',', ',' + vFieldTemp+ '.'  , [rfReplaceAll]);  //Categoria.Codigo, Categoria.Empresa

                            setLength(vFieldNames, length(vFieldNames)+1);
                            vFieldNames[high(vFieldNames)] := vFieldTemp;
                          end;

                      end;
                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.GetParamNames(aClass: T): TArray<string>;
  var
    vIterator: Integer;
begin
  Result := TSqlExtractor<T>.GetFieldnames(aClass);
  for vIterator := 0 to Length(Result) do
    Result[vIterator] := ':' + Result[vIterator];

end;

class function TSqlExtractor<T>.GetFieldnames(aClass: T): TArray<string>;
  var vFieldNames: TArray<String>;
begin
  SetLength(vFieldNames, 0);
  With TRttiInterceptor<T> do
    mapfield(aClass, procedure (aField: TRttiField)
                     begin
                      SetLength(vFieldNames, length(vFieldNames) + 1);
                      vFieldNames[high(vFieldNames)] := ExtractTablename(aClass) + '.' + aField.Name;
                     end);

  result := vFieldNames;
end;

class function TSqlExtractor<T>.Join(aArray: TArray<String>; aJoining: String): String;
var
  i : Integer;
begin
  Result := '';
  for i := low(aArray) to high(aArray) do
    Result := Result + aArray[i] + aJoining;

  for I := 1 to length(aJoining) do
    Delete(Result, Length(Result), 1);
end;

{ TSizeAttribute }

constructor TamanhoAttribute.Create(aSize: integer);
begin
  fSize := aSize.ToString;
end;

{ TPrecision }

constructor PrecisionAttribute.Create(aSize, aDecimals: integer);
begin
  fSize := aSize.ToString;
  fDecimals := aDecimals.ToString;
end;

{ TKeyAttribute }

constructor KeyAttribute.Create(aCampoChave: String);
begin
  fCampoChave := aCampoChave;
end;

{ TTablenameAttribute }

constructor TablenameAttribute.Create(aNomeTabela: String);
begin
  fNomeTabela := aNomeTabela
end;

{ TUniqueAttribute }

constructor UniqueAttribute.Create(aCampos: String);
begin
  fUniqueCampos := aCampos;
end;

{ TForeignKeyAttribute }

constructor ForeignKeyAttribute.Create(aCampo: String);
begin
  fForeignKeyCampo := aCampo;
end;

{ TLookupAttribute }

constructor LookupAttribute.Create(aCampo: String);
begin
  fLookupCampo := aCampo;
end;

end.
