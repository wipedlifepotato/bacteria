#pragma once
#define luaL_reg      luaL_Reg
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <errno.h>
#include<dirent.h>

void runAllLuaFilesInDir(lua_State * L, const char * pathdir);
