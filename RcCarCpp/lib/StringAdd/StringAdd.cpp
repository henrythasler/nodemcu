/**
 * A small class for adding different primary types to a "string"
 * by Thomas Mangel, Munich 2021 
 */

#include "StringAdd.h"

void (*memfree)(void *) = free;
char buff[50];

StringAdd::StringAdd(int buffer_size_){
  pos = 0;
  buffer_size = buffer_size_;
  mem = (char*) malloc(buffer_size_ * sizeof(char));
  allocated_buffer = true;
  mem[pos] = '\0'; // string end terminator
}

StringAdd::StringAdd(char * existing_buffer, int buffer_size_){
  pos = 0;
  allocated_buffer = false;
  buffer_size = buffer_size_;
  mem = existing_buffer;
  mem[pos] = '\0'; // string end terminator
}

void StringAdd::free(){
  if (allocated_buffer){
    memfree(mem);
  }
}
void StringAdd::add(char const * add_string){
  int len = strlen(add_string);
  add(add_string, len);
}

void StringAdd::add(char const * add_string, int length){
  strncpy(mem + pos, add_string, length);
  pos += length;
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

void StringAdd::add(int num){
	itoa(num, buff, 10);
  strncpy(mem + pos, buff, strlen(buff));
  pos += strlen(buff);
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

void StringAdd::add(unsigned int num){
	utoa(num, buff, 10);
  strncpy(mem + pos, buff, strlen(buff));
  pos += strlen(buff);
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

void StringAdd::add(unsigned long num){
	ultoa(num, buff, 10);
  strncpy(mem + pos, buff, strlen(buff));
  pos += strlen(buff);
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

void StringAdd::add(float num){
  dtostrf(num,3,3,buff);
  strncpy(mem + pos, buff, strlen(buff));
  pos += strlen(buff);
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

void StringAdd::add(double num){
  dtostrf(num,3,3,buff);
  strncpy(mem + pos, buff, strlen(buff));
  pos += strlen(buff);
  mem[pos * sizeof(char)] = '\0'; // string end terminator
}

char* StringAdd::getBuff(){
  return mem;
}
