# SqlExtractor
Extract SQL from the object structures

```delphi
type

TOrder = class
  FID: string;
  FVendor: integer;
  FCustomer: integer;
  FDate: TDatetime;
  FTotal: Currency;
end;

strSelect := TSqlExtractor<TPedido>.ExtractSelectSql(vPedido)
```
```bash
>> strSelect = 'select id, vendor, customer, date, total from order'
```
# Using anottations
You can use Custom Attributes as anottations to customize sql of a object

```delphi
type

TOrder = class
  [KEY]
  FID: string; //Now ID is Primary Key
  FVendor: integer;
  FCustomer: integer;
  FDate: TDatetime;
  FTotal: Currency;
end;

strSelect := TSqlExtractor<TPedido>.ExtractUpdateSql(vPedido)
```
```bash
>> strSelect = 'update order set id = :id, vendor = :vendor, customer = :customer, date=:date, total=:total where ID = :id'
```
