#ifdef __cplusplus
extern "C" {
#endif
#pragma once
#define eprintf(...) fprintf (stderr, __VA_ARGS__)
#define EXIT_FAILURE 1

#define MAX_LISTEN 100

#define PROGRAM_INFO __DATE__ "\tBacteria\t" __TIME__
#ifndef __cplusplus
typedef enum{false,true}bool;
#else
#endif

#define INITHASHFUNC(name, outputstringsize)\
	unsigned char hash[name##_DIGEST_LENGTH];\
	name##_CTX _##name;\
	name##_Init(&_##name);\
	name##_Update(&_##name, data, strlen(data));\
	name##_Final(hash, &_##name);\
    	for(int i = 0; i < name##_DIGEST_LENGTH; i++)\
    	{\
        	sprintf(outputstring + (i * 2), "%02x", hash[i]);\
    	}\
	outputstring[outputstringsize]=0;

#ifdef __cplusplus
}
#endif
