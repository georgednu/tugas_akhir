#include "states.h"

void update_state (State* curr_state, int* is_data_incoming, int* is_load_pl){
    
    State next_state = IDLE;
    
    switch (*curr_state) {

    case IDLE:
    if(*is_data_incoming){
        *is_data_incoming = 0;
        next_state = RECEIVING;        
    }else if(*is_load_pl){
        *is_load_pl = 0;
        next_state = LOAD_PL;
    }else{
        next_state = IDLE;        
    }
    break;

    case RECEIVING:
    next_state = IDLE;
    break;

    case LOAD_PL:
    if(*is_data_incoming){
        next_state = IDLE;        
    }else{
        next_state = RUN;
    }
    break;

    case RUN:
    if(*is_data_incoming){
        next_state = IDLE;        
    }
    break;

    default:
    next_state = IDLE;
    break;
    }

    *curr_state = next_state;

    return;
}