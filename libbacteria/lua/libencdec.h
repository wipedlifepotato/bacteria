#pragma once
#include"encdec/AES.h"
#include"encdec/x25519.h"
#include<openssl/sha.h>
#include"macros.h"
#include"encdec/hashes.h"

#include "lua.h"

#define MAXSIZEMSG 5012



int lua_genRandBytes (lua_State *L);
int lua_AESenc (lua_State *L);
int lua_AESdec (lua_State *L);
int lua_getKeyPair (lua_State *L);
int lua_freeKeyPair (lua_State *L);
int lua_freeSharedKey (lua_State *L);
int lua_createKeyPair (lua_State *L);
int lua_initKeyPairFromFile ( lua_State * L );
int lua_saveKeyPairToFile ( lua_State * L );
int lua_getSharedKey (lua_State *L);
int lua_freeAESData(lua_State *L);

INITLUAFUNC(getAESData);
INITLUAFUNC(getAESData_len);
INITLUAFUNC(createAESData);
INITLUAFUNC(getPubKey);
INITLUAFUNC(getPrivKey);
INITLUAFUNC(toSHA512);
INITLUAFUNC(toSHA256);
//INITLUAFUNC(setKeyPair);

struct lua_AESData{
	unsigned char * data;
	size_t size;
};


static const struct luaL_reg encdeclib [] = {
      {"genRandBytes", lua_genRandBytes},
      {"AESenc", lua_AESenc},
      {"AESdec", lua_AESdec},
      {"getKeyPair", lua_getKeyPair},
      {"freeKeyPair", lua_freeKeyPair},
      //{"freeSharedKey", lua_freeSharedKey},
      {"getSharedKey", lua_getSharedKey},
      {"createKeyPair", lua_createKeyPair},
      {"getSharedKey", lua_getSharedKey},
      {"freeAESData", lua_freeAESData},
      {"getAESData", lua_getAESData},
      {"initKeyPairFromFile", lua_initKeyPairFromFile},
      {"saveKeyPairToFile", lua_saveKeyPairToFile},
      LUAPAIR(getAESData_len)
      LUAPAIR(createAESData)
      LUAPAIR(getPubKey)
      LUAPAIR(getPrivKey)
      LUAPAIR(toSHA512)
      LUAPAIR(toSHA256)
//      LUAPAIR(setKeyPair)
      {NULL, NULL}
};
int luaopen_encdec (lua_State *L);

// Macross



	
