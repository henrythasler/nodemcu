/**
 * A small class for generating JSON strings wiht constant memory consumption
 * by Thomas Mangel, Munich 2021 
 */

#include "JsonObjectStr.h"

JsonObjectStr::JsonObjectStr(int buffer_size_){
  str = new StringAdd(buffer_size_);
  elem_num = 0;
}

JsonObjectStr::JsonObjectStr(char* existing_buffer, int buffer_size_){
  str = new StringAdd(existing_buffer, buffer_size_);
  elem_num = 0;
}

void JsonObjectStr::free(){
  str->free();
  delete str;
}

void JsonObjectStr::add(const char* key, char* value){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\":\"");
  str->add(value);
  str->add("\"");
  elem_num++;
}

void JsonObjectStr::addNull(const char* key){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\": null");
  elem_num++;
}

void JsonObjectStr::add(const char* key, int value){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\":");
  str->add(value);
  elem_num++;
}

void JsonObjectStr::add(const char* key, unsigned long value){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\":");
  str->add(value);
  elem_num++;
}

void JsonObjectStr::add(const char* key, float value){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\":");
  str->add(value);
  elem_num++;
}

void JsonObjectStr::add(const char* key, double value){
  if (elem_num == 0){
    str->add("{\"");
  } else {
    str->add(",\"");
  }
  str->add(key);
  str->add("\":");
  str->add(value);
  elem_num++;
}


void JsonObjectStr::finalize(){
    str->add("}");
}

char* JsonObjectStr::getBuff(){
  return str->getBuff();
}
