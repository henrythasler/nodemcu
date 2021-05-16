#include "Helper.h"
#include <Arduino.h>

unsigned long millisSinceStart()
{
    #if defined(ARDUINO_ARCH_ESP8266) //ESP8266
    return millis();
    #elif defined(ARDUINO_ARCH_ESP32) //ESP32
    return (unsigned long)(esp_timer_get_time() / 1000LL);
    #endif
}


unsigned char *bin_to_strhex(const unsigned char *bin, unsigned int binsz,
                             unsigned char **result)
{
    unsigned char hex_str[] = "0123456789abcdef";
    unsigned int i;

    (*result)[binsz * 2] = '\0';

    if (!binsz)
        return (NULL);

    for (i = 0; i < binsz; i++)
    {
        (*result)[i * 2 + 0] = hex_str[(bin[i] >> 4) & 0x0F];
        (*result)[i * 2 + 1] = hex_str[(bin[i]) & 0x0F];
    }
    return (*result);
}

unsigned char *strhex_to_bin(const char *str, unsigned int strsz, unsigned char *result)
{
    unsigned int i;
    int binsz = floor(strsz / 2.0);
    result[binsz] = '\0';

    if (!binsz)
        return (NULL);

    for (i = 0; i < binsz; i++)
    {
        result[i] = (unsigned char) hex2bin(str+(i*2));
    }
    return result;
}

int searchPos(const char *result, const char *test_str)
{
    int pos = -1;
    for (int i = 0; i < (strlen(result) - strlen(test_str) - 4); i += 2)
    {
        int same = strncmp(result + i, test_str, strlen(test_str));
        if (same == 0)
        {
            // printf("Pos: %d - %s\n", strlen(test_str), result + i);
            pos = i;
            break;
        }
    }
    printf("Pos: %d\n", pos);
    return pos;
}

/**
 * hex2uint
 * take a hex string and convert it to a 32bit unsigned number (max 8 hex digits)
 */
unsigned int hex2uint(const char *hex, int length)
{
    unsigned int val = 0;
    // printf("hex2int input: %s\n", hex);
    for (int i = 0; i < length; i++)
    {
        // get current character then increment
        unsigned int byte = *(hex + i);
        // transform hex character to the 4bit equivalent number, using the ascii table indexes
        if (byte >= '0' && byte <= '9')
            byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f')
            byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F')
            byte = byte - 'A' + 10;
        // shift 4 to make space for new digit, and add the 4 bits of the new digit
        val = (val << 4) | (byte & 0xF);
    }
    return val;
}

/**
 * hex2int
 * take a hex string and convert it to a 32bit number (max 8 hex digits)
 */
int hex2int(const char *hex, int length)
{
    unsigned int val = 0;
    int bit_0 = 0;
    // printf("hex2int input: %s\n", hex);
    for (int i = 0; i < length; i++)
    {
        // get current character then increment
        unsigned int byte = *(hex + i);
        // transform hex character to the 4bit equivalent number, using the ascii table indexes
        if (byte >= '0' && byte <= '9')
            byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f')
            byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F')
            byte = byte - 'A' + 10;
        if (i == 0){
            bit_0 = (byte & 0b1000) > 0 ? 1 : 0;
            // printf("b0: %d\n", bit_0);
        }
        // shift 4 to make space for new digit, and add the 4 bits of the new digit
        val = (val << 4) | (byte & 0xF);
    }
    int byte_int = sizeof(int);
    // printf("byte_int: %d\n", byte_int);
    if (bit_0 == 1) {
        for (int i = length; i < (byte_int * 2); i++){
           val = (0b1111 << i*4) + val; // In case bit0 is 1 we have a negative number => fill the precding bytes with 0xF until the whole byte of the INT representation is filled!
        }
    }
    return (int)val;
}

// Examples;
//   "00" -> 0
//   "2a" -> 42
//   "ff" -> 255
// Case insensitive, 2 characters of input required, no error checking
char hex2bin( const char *s )
{
    int ret=0;
    int i;
    for( i=0; i<2; i++ )
    {
        char c = *s++;
        int n=0;
        if( '0'<=c && c<='9' )
            n = c-'0';
        else if( 'a'<=c && c<='f' )
            n = 10 + c-'a';
        else if( 'A'<=c && c<='F' )
            n = 10 + c-'A';
        ret = n + ret*16;
    }
    return (char)ret;
}


int searchPos(const char *str, const char *find_str, int start_pos)
{
    int pos = -1;
    int len_find = strlen(find_str);
    int len_str  = strlen(str);
    for (int i = start_pos; i < (len_str - len_find); i += 1)
    {
        if (strncmp(str + i, find_str, len_find) == 0)
        {
            pos = i;
            break;
        }
    }
    return pos;
}
