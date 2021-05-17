/**
 * A small class for adding different primary types to a "string"
 * by Thomas Mangel, Munich 2021 
 */

#ifndef __STRING_ADD_H
#define __STRING_ADD_H

#include <Arduino.h>

class StringAdd {
  private:
    int   pos;
    char* mem; // the buffer to construct the string
    int   buffer_size;
    bool  allocated_buffer;

  public:
      StringAdd(int buffer_size_);
      StringAdd(char* existing_buffer, int buffer_size_);
      void add(char const * add_string);
      void add(char const * add_string, int length);
      void add(int num);
      void add(unsigned int num);
      void add(unsigned long num);
      void add(float num);
      void add(double num);
      void add(float num, int total_chars, int after_digit_chars);
      void add(double num, int total_chars, int after_digit_chars);
      char* getBuff();
      void free(); // free the memory if internal buffer!
};

#endif