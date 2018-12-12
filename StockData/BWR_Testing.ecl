IMPORT StockData;

#WORKUNIT('name', 'Stock Data: Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

ds := StockData.Files.Profiled.ds;
Dbg(ds);
