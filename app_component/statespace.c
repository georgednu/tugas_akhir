    #include "statespace.h"
    #include <stdint.h>

    void mat_vect_mul (int64_t* result, int64_t* matrix, int64_t* vect){
        for(int i = 0; i<MAX_ROW ; i++){
            result[i] = 0;
            for(int j = 0; j<MAX_COL ; j++){
                result[i] +=(matrix[i*MAX_COL+j]*vect[j])>>32; 
            }
        }
        return;
    }

    void add_identity (int64_t* mat){
        for(int i = 0 ; i < MAX_COL*MAX_ROW ; i++){
            mat[i] = (i%MAX_COL == i/MAX_ROW)? mat[i] + (1ll<<32) : mat[i];
        }
    }

    void matmul (int64_t* result, int64_t* left, int64_t* right){
        for(int i = 0; i<MAX_ROW ; i++){
            for (int j = 0 ; j<MAX_COL ; j++){
                result[i*MAX_COL+j] = 0;
                for (int k = 0 ; k<MAX_COL ; k++){
                    result[i*MAX_COL+j] += (left[i*MAX_COL+k] * right[k*MAX_COL+j])>>32;
                }
            }
        }
        return;
    }

    void discretize(StateSpace* plant, int64_t* ah_on,int64_t* ah_off,int64_t* bh_on,int64_t* bh_off, int64_t* C){
        int64_t ah_on_f [A_SIZE];
        int64_t ah_off_f [A_SIZE];
        int64_t bh_on_f [B_SIZE];
        int64_t bh_off_f [B_SIZE];

        for(int i = 0 ; i<A_SIZE ; i++){
            ah_on_f[i] = (plant->mat_Aon[i] * 2147ll);
        }
        
        for(int i = 0 ; i<A_SIZE ; i++){
            ah_off_f[i] = plant->mat_Aoff[i] * 2147ll;
        }
        
        for(int i = 0 ; i<B_SIZE ; i++){
            bh_on_f[i] = plant->mat_Bon[i] * 2147ll;
        }

        for(int i = 0 ; i<B_SIZE ; i++){
            bh_off_f[i] = plant->mat_Boff[i] * 2147ll;
        }

        add_identity(ah_on_f);
        add_identity(ah_off_f);

        for(int i = 0 ; i<A_SIZE ; i++){
            ah_on[i] = (int64_t)ah_on_f[i];
        }

        for(int i = 0 ; i<A_SIZE ; i++){
            ah_off[i] = (int64_t)ah_off_f[i];
        }

        for(int i = 0 ; i<B_SIZE ; i++){
            bh_on[i] = (int64_t)bh_on_f[i];
        }

        for(int i = 0 ; i<B_SIZE ; i++){
            bh_off[i] = (int64_t)bh_off_f[i];
        }

        for(int i = 0 ; i<C_SIZE ; i++){
            C[i] = (int64_t)plant->mat_C[i] << 32;
        }

        return;
    }