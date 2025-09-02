echo off
set LUA_PATH=%cd%/lua/?.lua;%cd%/util/?.lua;%cd%/lib/?.lua;%cd%/util/du-mocks/dumocks/?.lua;
du-lua build --copy=release/Saga