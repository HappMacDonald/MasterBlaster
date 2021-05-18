#define STDIN 0
#define STDOUT 1
#define STDERR 2

struct MasterBlasterString
{ uint64_t string;
  uint64_t length;
};

union Bytefield64
{ uint64_t d64;
  uint32_t d32[2];
  uint16_t d16[4];
  uint8_t  d8[8];
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

