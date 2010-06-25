#include <list>

namespace mynamespace {
  std::list<int> list_of_ints;

  void function() {}
  void function(int a, bool b) {}
  void function(int *a, bool b, void *c) {}
  void function(unsigned int a, char &b) {}
  void function(long a, ...) {}
  void function(const signed char *a) {}
  void function(signed char *const a) {}
  void function(const volatile float *a) {}
  void function(const double &a) {}

  class MyClass {
  public:
    MyClass();
    MyClass(int);
    ~MyClass();

    void method();
  };

  MyClass::MyClass() {}
  MyClass::MyClass(int a) {}
  MyClass::~MyClass() {}
  void MyClass::method() {}

  void function(MyClass a) {}
  void function(MyClass *a) {}
  void function(MyClass *a, MyClass b) {}
  void function(MyClass &a) {}
}
