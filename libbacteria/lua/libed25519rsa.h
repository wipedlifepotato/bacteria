#pragma once
#include"lua.h"
#include"encdec/rsa_ed25519.h"

INITLUAFUNC(generateKeysEd25519);
INITLUAFUNC(generateKeysRSA);
INITLUAFUNC(initPrivKey);
INITLUAFUNC(signIt);
INITLUAFUNC(verifyIt);
INITLUAFUNC(freeaKey);

INITLUAFUNC(getaPubKey);
INITLUAFUNC(getaPrivKey);

//INITLUAFUNC(Base64Decode);
//INITLUAFUNC(Base64Encode);

static const struct luaL_reg libed25519rsa [] = {
//	LUAPAIR(getAESData_len)
LUAPAIR(generateKeysEd25519)
LUAPAIR(generateKeysRSA)
LUAPAIR(initPrivKey)
LUAPAIR(signIt)
LUAPAIR(verifyIt)
LUAPAIR(freeaKey)
LUAPAIR(getaPubKey)
LUAPAIR(getaPrivKey)
{NULL,NULL}
//LUAPAIR(getPrivPubRaw)
};

int luaopen_libed25519rsa (lua_State *L);
