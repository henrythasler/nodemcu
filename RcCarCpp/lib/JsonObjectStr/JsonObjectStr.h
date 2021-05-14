/**
 * A small class for generating JSON strings wiht constant memory consumption
 * by Thomas Mangel, Munich 2021 
 */

#ifndef __JSON_OBJ_STR_H
#define __JSON_OBJ_STR_H

#include <Arduino.h>
#include <StringAdd.h>

class JsonObjectStr {
  private:
    StringAdd* str;
    int elem_num;

  public:
      JsonObjectStr(int buffer_size_);
      JsonObjectStr(char* existing_buffer, int buffer_size_);
      void add(const char* key, char* value);
      void add(const char* key, int   value);
      void add(const char* key, unsigned long value);
      void add(const char* key, float value);
      void add(const char* key, double value);
      void addNull(const char* key);
      void finalize();
      char* getBuff();
      void free(); // free the memory if internal buffer!
};

#endif