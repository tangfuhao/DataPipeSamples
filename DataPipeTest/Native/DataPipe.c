//
//  DataPipe.c
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

#include "DataPipe.h"
#include <stdlib.h>


//implement for pull data
void cs_data_pipe_pull_data_implement(CSDataPipe *dataPipe, PullCallBackPtr pullCallBack) {
    CSProcessUnit* outputNode = dataPipe->_outPutNode;
    CSDataWrap* dataWrap = cs_process_unit_process(dataPipe, outputNode);
    pullCallBack(dataWrap);
}

PullCallBackPtr cs_data_pipe_wait_callBack(CSDataPipe *dataPipe) {
    PullCallBackPtr callBack = dataPipe->_callback;
    
    while (callBack == NULL) {
        pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
        callBack = dataPipe->_callback;
        dataPipe->_callback = NULL;
        pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    }
    return callBack;
}

int cs_data_pipe_wait_type(CSDataPipe *dataPipe) {
    //wait type determines
    while (dataPipe->_type == 0) {
        pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
        pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    }
    return dataPipe->_type;
    
}

void cs_data_pipe_process_pull(CSDataPipe *dataPipe) {
    //whether is over for each round
    while (!(dataPipe->_status & CS_DP_STATUS_CLOSE)) {

        //whether determines callback
        PullCallBackPtr callBack = NULL;
        if(!(callBack = cs_data_pipe_wait_callBack(dataPipe))) {
            continue;
        }
        
        cs_data_pipe_pull_data_implement(dataPipe,callBack);
    }
}

void cs_data_pipe_process_push(CSDataPipe *datapipe) {
    
}


static void* cs_data_pipe_thread_proc(void *param)
{
    CSDataPipe   *dataPipe = (CSDataPipe*)param;

    while (!(dataPipe->_status & CS_DP_STATUS_CLOSE)) {
        //whether determines type
        if (!cs_data_pipe_wait_type(dataPipe)){
            continue;
        }
        
        if(dataPipe->_type == CS_DP_TYPES_PUSH) {
            cs_data_pipe_process_push(param);
        }else if(dataPipe->_type == CS_DP_TYPES_PULL) {
            cs_data_pipe_process_pull(param);
        }else {
            dataPipe->_status = CS_DP_STATUS_CLOSE;
        }
    }
    return NULL;
}



CSDataPipe* cs_data_pipe_create(void) {
    CSDataPipe *dataPipe = NULL;
    // alloc dataPipe context
    dataPipe = (CSDataPipe*)calloc(1, sizeof(CSDataPipe));
    if (!dataPipe) return NULL;
    
    //init
    pthread_mutex_init(&dataPipe->_status_sync_mutex, NULL);
    pthread_cond_init(&dataPipe->_status_sync_cond, NULL);
    pthread_cond_init(&dataPipe->_params_sync_cond, NULL);
    pthread_create(&dataPipe->process_thread, NULL, cs_data_pipe_thread_proc, dataPipe);
    
    
    return dataPipe;
}

void cs_data_pipe_release(CSDataPipe* dataPipe) {
    free(dataPipe);
}

void cs_data_pipe_resume(CSDataPipe* dataPipe) {
    
}

void cs_data_pipe_pause(CSDataPipe* dataPipe) {
    
}

void cs_data_pipe_pull_data(CSDataPipe* dataPipe,PullCallBackPtr callback) {
    
}



CSDataWrap* cs_process_unit_on_process(CSDataPipe *dataPipe, CSProcessUnit* unit) {
    if(unit->_onProcessFunc != NULL){
        unit->_onProcessFunc();
    }
    return unit->_outputData;
}


void cs_process_unit_process_dependent(CSDataPipe *dataPipe, CSProcessUnit* unit) {
    for (int i = 0; i < unit->_dependentUnitCount; i++) {
        CSProcessUnit* childUnit = unit->_dependentUnitPtr[i];
        cs_process_unit_process(dataPipe, childUnit);
    }
    
    for (int i = 0; i < unit->_dependentSourceCount; i++) {
        CSDataSource* childSource = unit->_dependentSourcePtr[i];
        cs_process_source_process(dataPipe, childSource);
    }
}

void cs_process_unit_on_init(CSDataPipe *dataPipe, CSProcessUnit* unit) {
    if (unit->_onIntFunc != NULL) {
        unit->_onIntFunc();
        unit->_status = unit->_status | CS_PU_STATUS_INIT;
    }
}

CSDataWrap* cs_process_unit_process(CSDataPipe *dataPipe, CSProcessUnit* unit) {
    
    //on init
    if (!(unit->_status & CS_PU_STATUS_INIT)){
        cs_process_unit_on_init(dataPipe, unit);
    }
    
    //on process
    cs_process_unit_process_dependent(dataPipe, unit);
    return cs_process_unit_on_process(dataPipe, unit);
}

CSDataWrap* cs_process_source_process(CSDataPipe *dataPipe,CSDataSource *dataSource) {
    return NULL;
}
