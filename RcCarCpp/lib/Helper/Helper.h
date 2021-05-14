#ifndef __HELPER_H
#define __HELPER_H

unsigned long millisSinceStart();
unsigned char *bin_to_strhex(const unsigned char *bin, unsigned int binsz, unsigned char **result);
unsigned char *strhex_to_bin(const char *str, unsigned int strsz, unsigned char *result);
int searchPos(const char *result, const char *test_str);
int searchPos(const char *str, const char *find_str, int start_pos);
unsigned int hex2uint(const char *hex, int length);
int  hex2int(const char *hex, int length);
char hex2bin(const char *s );

#endif