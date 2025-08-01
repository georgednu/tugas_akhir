#ifndef STATES
#define STATES

typedef enum State {IDLE, RECEIVING, LOAD_PL, RUN} State;

void update_state (State* curr_state, int* is_data_incoming, int* is_load_pl);

#endif