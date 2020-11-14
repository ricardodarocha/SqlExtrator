unit Test.SqlExtractor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.Generics.Collections, Assis.SQLExtractor;

type

  TItem = class
    [key('Id')]
    ID: VARCHAR;
    Description: VARCHAR;
    Price: Currency;

  end;

  TOrder = class
    [key]
    ID: VARCHAR;
    Vendor: integer;
    Customer: integer;
    Date: TDatetime;
    Total: Currency;

    [ForeignKey('Id')]
    ITem: TObjectList<TItem>;

    constructor Create;
    destructor Destroy; override;

  end;

  TformTestSqlExtractor = class(TForm)
    Memo1: TMemo;
    Combobox1: TComboBox;
    procedure ComboBox1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  formTestSqlExtractor: TformTestSqlExtractor;

implementation

{$R *.dfm}

procedure TformTestSqlExtractor.ComboBox1Change(Sender: TObject);
type
  tSqlKind = (sqlCREATETABLE, sqlSELECT, sqlINSERT, sqlUPDATE, sqlDELETE);
var
  sqlKind: tSqlKind;
  Order: TOrder;

begin

  Order := TOrder.Create;

  try
    sqlKind := tSqlKind(Combobox1.ItemIndex);
    case sqlKind of
      sqlCREATETABLE : Memo1.lines.Text := TSqlExtractor<TOrder>  .ExtractCreateTableSql(Order);
      sqlSELECT      : Memo1.lines.Text := TSqlExtractor<TOrder>  .ExtractSelectSql(Order);
      sqlINSERT      : Memo1.lines.Text := TSqlExtractor<TOrder>  .ExtractInsertIntoSql(Order);
      sqlUPDATE      : Memo1.lines.Text := TSqlExtractor<TOrder>  .ExtractUpdateSql(Order);
      sqlDELETE      : Memo1.lines.Text := TSqlExtractor<TOrder>  .ExtractDeleteSql(Order);
    end;
  finally
    FreeAndNil(Order);
  end;

end;

{ TOrder }

destructor  TOrder.Destroy;
begin
  inherited;
  Item.Free;
end;

constructor TOrder.Create;
begin
  ITem := TObjectList<TItem>.Create;
end;

end.
