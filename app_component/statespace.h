#ifndef STATESPACE
#define STATESPACE

#include "xil_types.h"
#include "specs.h"
#include "math.h"

//StateSpace matrix type
struct StateSpace {
    int32_t u;
    int32_t mat_Aon [A_SIZE];
    int32_t mat_Bon [B_SIZE];
    int32_t mat_Aoff [A_SIZE];
    int32_t mat_Boff [B_SIZE];
    int32_t mat_C [C_SIZE];
    int32_t mat_D [D_SIZE];
    int64_t size;
};


typedef struct StateSpace StateSpace;



#endif