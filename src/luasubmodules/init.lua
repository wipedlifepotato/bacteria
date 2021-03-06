local submoduledir = "./luasubmodules/"
json = require "json"
sql = require "luasql.postgres"

bacteria = require (submoduledir .. "bacteria")
bacteria_aes = require (submoduledir .. "bencdec")
gd = require ( submoduledir .. "gd" )
--gmp = require ( submoduledir .. "gmp" )

bacteria.init("cryptocoins.ini",{'tgst','tdash'})
bacteria.dumpCryptocoins()

function extended (child, parent)
    setmetatable(child,{__index = parent}) 
end

-- events
--int sock, const char * uIp, uint16_t uPort, char* buf
local opcodes={}
opcodes["pisk"] = function (sock,ip,port,buf) 
	local key = buf
	while string.len(key) ~= 32 do
		if string.len(key) > 32 then
			key=string.sub(key,0,32)
		else
			key=key.."0"
		end
	end
	print("Test opcode, key: ", key) 
	while 1 == 1 do
	socklen, rbytes, msg = lnet.recv(sock,1024)
	if msg == nil then break end
	if string.len(msg) > 1 then
		break
	end
	end
	aes=bacteria_aes:new(key, "1234567890123451")
	print("key:", aes:getKey(), "IV: ",aes:getIV())
	aes:encrypt(msg, AESENCType["t_aescbc"]) -- b:getAESData_rawEnc()
	aesdata,sz=aes:getAESData_enc()
	aes:clear()	
	return "Test opcode: ".. string.tohex(aesdata)
end 
opcodes["pizd"] = function (sock,ip,port,buf) 
	local key = buf
	while string.len(key) ~= 32 do
		if string.len(key) > 32 then
			key=string.sub(key,0,32)
		else
			key=key.."0"
		end
	end

	print("Test opcode, key: ", key) 
	while 1 == 1 do
	socklen, rbytes, msg = lnet.recv(sock,1024)
	if msg == nil then break end
	if string.len(msg) > 1 then
		break
	end
	end
	aes=bacteria_aes:new(key, "1234567890123451")
	aes:setAESData_enc( string.fromhex(msg) )
	aes:decrypt(aes:getAESData_rawEnc(), AESENCType["t_aescbc"])
	aesdata,saesdata=aes:getAESData_dec()
	aes:clear()	
	if aesdata == nil then return "NIL!" end
	return "Test opcode: ".. aesdata
end 
function undefined_event(sock, ip, port, buf, opcode)
	print("Opcode: ", opcode)
        local ropcode = string.sub(opcode, 1, 4)

	if  opcodes[ropcode] == nil then
		return nil
	end

	return opcodes[ropcode](sock,ip,port,buf)
--	print( opcodes["test"] )
--	print("Opcode: ", ropcode, " Not found")
--	return nil
end
function event1(sock, ip, port, buf)
	print("Message: ", buf, " from ", ip, " on port: ", port)
	keys = ed25519rsa.generateKeysRSA(nil, 2048, 3)
	pubkey = ed25519rsa.getaPubKey(keys)
	lnet.send(sock,"Test?")
	while 1 == 1 do
		socklen, rbytes, msg = lnet.recv(sock,1024)
		if msg == nil then break end
		if string.len(msg) > 1 then
			break
		end
	end
	print("Replay: ", msg)
	return pubkey
end

-- end events


function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end


local function check_leak_memory(fcoin,scoin) 
		tmp=bacteria.doRPCRequest(fcoin, "getbalance", {"*",6})
		tmp1=bacteria.doRPCRequest(scoin, "getbalance", {"*",6})

		local iter=65535 -- check to memory leak --
		--while 1 == 1 do
		while iter > 65535 do
			iter=iter-1
			bacteria.doRPCRequest(tgst, "getbalance", {"*",6})
			bacteria.doRPCRequest(sgst, "getbalance", {"*",6})
		end
		print(tmp1['result'])
		--print(tmp)
		print(tmp['result'])
end 

local function CryptocoinsTest()
	--tgst=cryptocoins.gettable(t,'tgst')
	--tdash=cryptocoins.gettable(t,'tdash')
	tgst = bacteria.coins['tgst']
	tdash = bacteria.coins['tdash']
	check_leak_memory(tgst,tdash)


	-- example in luasubmodules/bencdec.lua
	--key,iv=bacteria_aes.genKeyIV()
end


local function addChar(ch,time)
	ret=""
	while time > 0 do
		ret = ret .. ch
		time = time - 1
	end
	return ret
end

local function checkAllTypes(b,msg) -- 
--	b:encrypt(msg)
--	b:decrypt( b:getAESData_rawEnc() )
--	b:clear()
	for index, data in pairs(AESENCType) do
	    --if data ~= AESENCType["t_chacha20"] then
	    	print(index,data)		
		b:encrypt(msg,data)
		b:decrypt( b:getAESData_rawEnc(),data )
		aesdata_enc,saesdata_enc=b:getAESData_enc()
		b:decrypt(b:getAESData_rawEnc(), data)
		aesdata_dec,saesdata_dec=b:getAESData_dec()
		b:clear()  
		print("Decrypt msg: ", aesdata_dec)
--
	   -- end

	end

	
end
local function EncDecTest()
	msg="Hello AES_ECB, AES_CBC, ChaCha20! "
	msg=msg .. addChar("s",666)

	b=bacteria_aes.new() --("mysmallkey") -- ("mykey","myiv") 32,16 bytes
	print("key:", string.len(b:getKey()), "IV: ",string.len(b:getIV()))
	print("AES check!")
	checkAllTypes(b,"is example message aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaafasdjasdjkfsdfjasdfjiaodfasdfjiasdijfasidfadfiaojsdijfoasdfiaojsdfiojasdfijasdfuhasdufhasdiufhasidufashdfiasudhfiasudhfiuasdfihuSOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOFSDJKFASDJFASJDFQJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
	print("\n\n\n\n\n\n\n\n\n\nx25519 + AES check!\n\n\n\n\n\n\n\n\n\n")
	k1 = bacteria_aes:newKeyPair()
	k2 = bacteria_aes:newKeyPair()
	k1:initKeyPair()
	k2:initKeyPair()
	pub1 = k1:getPubKey()
	pub2 = k2:getPubKey()
	priv2 = k2:getPrivKey()
	k2:saveKeyPairToFile("x25519.dat")
	--k4 = bacteria_aes.new()
	k4 = bacteria_aes:newKeyPair()

	k4:initKeyPairFromFile("x25519.dat")
	
	if( string.len(string.tohex(pub1)) ~= 64 or string.len(string.tohex(pub2)) ~= 64 )
	then
		print("TODO: create test for initKeyPair sizes of keys")
		print("NOW: there is not normal size of pubkey, restart test")
		return EncDecTest()
	end
	print("Pub1: ", string.tohex(pub1), string.fromhex(string.tohex(pub1)) == pub1 )
	print("Pub2: ", string.tohex(pub2), string.fromhex(string.tohex(pub2)) == pub2 )

	k3 = bacteria_aes:newKeyPair()
	k3:initKeyPair(pub2,priv2)
	--print("Pub1: ", pub1)
	--print("Priv2: ", priv2)
	--print("Pub2: ", pub2)

	pub3 = k3:getPubKey()
	priv3 = k3:getPrivKey()

	--print("Pub3: ", pub3)
	--print("Priv3: ", priv3)

	shared0=k1:getSharedKey(pub2)
	shared1=k2:getSharedKey(pub1)
	shared2=k3:getSharedKey(pub1)
	shared3 = k4:getSharedKey(pub1)
	if not shared3 == shared1 then
		error("Shared3 key not = shared1 key")
	end
	--print("Shared0:", shared0)
	--print("Shared1:", shared1)

	aes1=bacteria_aes:new(shared0, "1234567890123451")
	aes=bacteria_aes:new(shared1, "1234567890123451")
	aes1:encrypt("TestMsg W10013291825328197ASHFASDF8932ASDF8532BUSAFD893251BSDFA78532BFW783125HBSFAD789aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaafasdjasdjkfsdfjasdfjiaodfasdfjiasdijfasidfadfiaojsdijfoasdfiaojsdfiojasdfijasdfuhasdufhasdiufhasidufashdfiasudhfiasudhfiuasdfihuSOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOFSDJKFASDJFASJDFQJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
	--print("Encrypted")
	aes:decrypt(aes1:getAESData_rawEnc())
	aesdata_dec,saesdata_dec=aes:getAESData_dec()
	print("Decrypted: ", aesdata_dec)

	k1.clear()
	k2.clear()
	k3.clear()
end

-- new take array 
-- local color ={}
-- color['green'] = 0	color['red']=0
-- color['alpha'] = 0	color['blue']=0
-- gd:new(120,120,50,color)
-- in another parts color is will be INT color
local function checkGD(gdbusedraw,width,height,quality,color)
	img = gd:new(width,height,quality,color)
	print("initImage")
	img:initImage() -- can get background color, int not array
	print("add red color")
	img:addColor("red", 255, 0, 0, 255)
	print("initColors")
	greenColor = img:getColor(0,255,0,255)
	redColor = img:foundColor("red")
	randColor = img:getRandColor()
	print("Sleep one second for another rand color")
	sleep(1)
	randColor1 = img:getRandColor()
	print("done")
	print("draw random")
	img:drawRandomLines(100) -- count
	img:drawRandomPixels(30,100) -- min count, max count
	print("draw rect")
	img:drawRect(0,0, 30, 30, redColor)
	img:drawRect(30,30, 60,60, randColor1)
	img:drawRect(60,60,90,90, greenColor)
	img:drawRect(90,90,120,120, img:getRandColor())
	print("drawLine")
	img:drawLine(0,0,width,height, randColor)
	img:setDefFont("./fonts/dummy.ttf")
	--can take defFont
	--12 and 15 is ptSize; 0.5 and -0.2 is angle; width/2 is x;... height/2 is y;
	print("drawText")
	img:drawText("zdarova ilia", width/2,height/2, randColor1, 12, 0.5, "./fonts/dummy.ttf")
	img:drawText("iluha drov", width/3, height/3, randColor1, 15, -0.2) 
	
	print("save to file test.jpg")
--function obj:setQuality(q) ; so img:setQuality(100) for 100 quality before save; getQuality for get current quality
	img:saveToFile("test.jpg")
	rawdata, size_rawdata = img:getRawImage()
	print("Size of img: ", size_rawdata)
	if gdbusedraw then print("RawData: ", rawdata) end
	img:clear()
end
local function GMPTEST()
	print("GMP")
	myZ = lgmp.mpz_init()
	lgmp.mpz_add_ui(myZ,myZ, 5)
	lgmp.mpz_add_ui(myZ,myZ, 1)
	--6
	lgmp.mpz_mul(myZ,myZ, myZ)
	--6*6 = 36
	lgmp.mpz_mul_ui(myZ,myZ, 5)
	--36*5 = 180
	myZ1 = lgmp.mpz_init_str("5")
	lgmp.mpz_div(myZ,myZ,myZ1)
	print("New value is:(will be 36)",lgmp.mpz_getstr(myZ, 128))
	lgmp.mpz_sub_ui(myZ,myZ, 40)
	print("New value is:(will be -4)",lgmp.mpz_getstr(myZ, 128))
	lgmp.mpz_clear(myZ)

	myF = lgmp.mpf_init()
	lgmp.mpf_add_ui(myF, myF, 10)
	lgmp.mpf_add_ui(myF, myF, 10)

	myF1 = lgmp.mpf_init_str("321.0234")
	lgmp.mpf_add(myF, myF1,myF1)
	print("New value is:",lgmp.mpf_getstr(myF1, 128))
	lgmp.mpf_mul(myF1, myF1,myF1)
	print("New value is:",lgmp.mpf_getstr(myF1, 128))
	lgmp.mpf_div(myF1, myF1,myF)

	print("New value is:",lgmp.mpf_getstr(myF1, 128))
	lgmp.mpf_clear(myF)
	lgmp.mpf_clear(myF1)
end

function checkRetVal(n)
	if n == 10 then return "String" end
--	print(n)
--	print("will be returned: ", n*2%7)
	return (n*2 % 7)
end

	--iwould not write much before ed25519rsa.verifyIt, there is bag.
	-- or set enter before isVerified, much enters!
	-- just not write much before C api call (print)
local function checkEd25519rsa ()
	print("ed25519")
	ed = ed25519rsa.generateKeysEd25519("ed25519.privkey")
	print("Generate")
	ed_ = ed25519rsa.initPrivKey("ed25519.privkey",true) -- true is ed25519
	pubKey = ed25519rsa.getaPubKey(ed_)
	pubKey1 = ed25519rsa.getaPubKey(ed)
	print("PubKey: ", string.tohex(pubKey))
	print("PubKey1: ", string.tohex(pubKey1))

	if(pubKey == pubKey1) then
		print("Correct init privKeys (ed25519)")
	end
	print("RSA")

	rsa = ed25519rsa.generateKeysRSA("rsa.privkey", 2048, 3) -- 8192,4
	rsa_ = ed25519rsa.initPrivKey("rsa.privkey",false)

	print("getPubKey")

	pubKey = ed25519rsa.getaPubKey(rsa)
	pubKey1 = ed25519rsa.getaPubKey(rsa_)
	print("PubKey: ", pubKey)
	print("PubKey1: ", pubKey1)
	if(pubKey == pubKey1) then
		print("Correct init privKeys (RSA)")
	end

	print("PrivKeys")
	print( "ed25519",string.tohex(ed25519rsa.getaPrivKey(ed)) )
	print("RSA", ed25519rsa.getaPrivKey(rsa) )

	print("\n\nCheck sign and verify\n\n")
	msgtosign = "testMsg"
	sign, ssign = ed25519rsa.signIt(ed, msgtosign )
	print("Sign: ", string.tohex(sign), " size of sign: ", ssign)
	print("verify check")

	ed1 = ed25519rsa.generateKeysEd25519()
	pubkey,spubkey=ed25519rsa.getaPubKey(ed)
	print("spubkey", spubkey)
	print("pubkey", pubkey)
	print("...")
	isVerified = ed25519rsa.verifyIt(sign, ssign, msgtosign, pubkey, spubkey, true)
	print("check correct pubkey")
	if isVerified then
		print("Is verified!")
	else
		print("is not verified!")
	end
	pubkey,spubkey=ed25519rsa.getaPubKey(ed1)
	--iwould not write much before ed25519rsa.verifyIt, there is bag.
	-- or set enter before isVerified, much enters!
	isVerified = ed25519rsa.verifyIt(sign, ssign, msgtosign, pubkey, spubkey, true)
	print("Check not correct pub key")
	if isVerified then
		print("Is verified!")
	else
		print("Is not verified")
	end
	ed25519rsa.freeaKey(ed1)
	print("verify check RSA")

	rsa1 = ed25519rsa.generateKeysRSA(nil,2048,3)

	pubkey,spubkey=ed25519rsa.getaPubKey(rsa)
	print("spubkey", spubkey)
	print("pubkey", pubkey)
	print("...")

	isVerified = ed25519rsa.verifyIt(sign, ssign, msgtosign, pubkey, spubkey, false)

	print("check correct pubkey")
	if isVerified then
		print("Is verified!")
	else
		print("is not verified!")
	end

	pubkey,spubkey=ed25519rsa.getaPubKey(rsa1)

	--iwould not write much before ed25519rsa.verifyIt, there is bag.
	-- or set enter before isVerified, much enters!

	isVerified = ed25519rsa.verifyIt(sign, ssign, msgtosign, pubkey, spubkey, false)

	print("Check not correct pub key")
	if isVerified then
		print("Is verified!")
	else
		print("Is not verified")
	end

	ed25519rsa.freeaKey(rsa1)

	print("ClearKeys")

	ed25519rsa.freeaKey(ed)
	ed25519rsa.freeaKey(ed_)
	ed25519rsa.freeaKey(rsa)
	ed25519rsa.freeaKey(rsa_)
end
checkEd25519rsa ()
GMPTEST()
CryptocoinsTest()
EncDecTest()

gdbusedraw=false
checkGD(gdbusedraw,120,120,100,color)


mytable={key="value", sdfasdf=123, s03="321"}
mytable["p1"]="e"
packed = lnet.packData(mytable)
print("Packed - ", packed)
unpacked = lnet.unpackData(packed)
print("Upacked: ",unpacked["key"], unpacked["sdfasdf"], unpacked.s03)
--todo check lnet. sockets funcs
print( lnet.join_addresses("1", "23", "dcba", "abcd","127.0.0.1","192.168.0.0.1", "ffff:ffff:fff:ffff:fffffff") )
print(lnet.join_data("0.0.0.0","1.1.1.1") )
print(lnet.join_data("30203032023","3040320", ',') )

