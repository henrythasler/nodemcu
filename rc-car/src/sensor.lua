--[[
local db = sqlite3.open("sensors.sqlite")
if db then
    print("SQLite version: " .. sqlite3.version())
    --db:exec("CREATE TABLE test (id INTEGER PRIMARY KEY, time timestamp, ACLNX REAL, ACLNY REAL);")
    --db:exec("INSERT INTO test VALUES (NULL, '2018-09-24 20:00:00', 0.43, 0.01);")

    db:exec("CREATE TABLE outside(temp INT, hum INT);")
    db:exec("INSERT INTO outside(temp, hum) VALUES(1, 2);")


    db:close()
end
]]--

local db = sqlite3.open("sensors.sqlite")
sql=[=[
    CREATE TABLE numbers(num1,num2,str);
    INSERT INTO numbers VALUES(1,11,"ABC");
    INSERT INTO numbers VALUES(2,22,"DEF");
    INSERT INTO numbers VALUES(3,33,"UVW");
    INSERT INTO numbers VALUES(4,44,"XYZ");
    SELECT * FROM numbers;
  ]=]
  function showrow(udata,cols,values,names)
    assert(udata=='test_udata')
    print('exec:')
    for i=1,cols do print('',names[i],values[i]) end
    return 0
  end
  db:exec(sql,showrow,'test_udata')