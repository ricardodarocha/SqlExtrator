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

strSelect := TSqlExtractor<TOrder>.ExtractSelectSql(vOrder)
```
```bash
>> strSelect = 'select id, vendor, customer, date, total from order'
```
# Using annotations
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

strSelect := TSqlExtractor<TOrder>.ExtractUpdateSql(vOrder)
```
```bash
>> strSelect = 'update order set id = :id, vendor = :vendor, customer = :customer, date=:date, total=:total where ID = :id'
```
# Extracting Inner join

In this example I'm using a generic list of objects to generate a Inner Join expression
```delphi
type
TItem = class
  FDescription: String;
  FPrice: Currency;
end;

TOrder = class
  [KEY]
  FID: string; //Now ID is Primary Key
  FVendor: integer;
  FCustomer: integer;
  FDate: TDatetime;
  FTotal: Currency;
  FItem: TObjectList<TItem>;
end;

strSelect := TSqlExtractor<TOrder>.ExtractUpdateSql(vOrder)
```
```bash
>> strSelect = select Order.ID, 
                      Order.Vendor,
                      Order.Customer,
                      Order.Date,
                      Order.Total,
                      Order.ITem  
                from Order 
                INNER JOIN Item as Item on Item.Id = Order.Item
```

It also would be a Single Instance of TItem
The given declaratin will return same sql 
```delphi
TOrder = class
  [KEY]
  FID: string; //Now ID is Primary Key
  FVendor: integer;
  FCustomer: integer;
  FDate: TDatetime;
  FTotal: Currency;
  FItem: TItem;
end;
```

