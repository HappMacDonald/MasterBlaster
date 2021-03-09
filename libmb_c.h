#define STDIN 0
#define STDOUT 1
#define STDERR 2

struct MasterBlasterString
{ uint64_t a;
  uint64_t b;
};

extern void putMemoryProcedure
( /*rdi*/ char *message
, /*rsi*/ uint64_t length
, /*rdx*/ uint64_t fileDescriptor
);

extern struct MasterBlasterString unsignedIntegerToStringBase16
( /*rdi*/ uint64_t valueToConvert
, /*rax*/ char resultBuffer[16] // Largest possible results are 16 digits
);

extern struct MasterBlasterString unsignedIntegerToStringBase10
( /*rdi*/ uint64_t valueToConvert
, /*rax*/ char resultBuffer[20] // Largest possible results are 20 digits
);

extern uint8_t TrigentasenaryUppercaseDigits[36];