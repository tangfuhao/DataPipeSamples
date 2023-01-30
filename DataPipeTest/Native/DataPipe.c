//
//  DataPipe.c
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

#include "DataPipe.h"
#include "DataPipe_Internal.h"
#include <stdlib.h>


//implement for pull data
void cs_data_pipe_pull_data_implement(CSDataPipeNative *dataPipe, PullCallBackPtr pullCallBack) {
    CSProcessUnitNative* outputNode = dataPipe->_outPutNode;
    CSDataWrapNative* dataWrap = cs_process_unit_process(dataPipe, outputNode);
    pullCallBack("1",dataWrap);
}

PullCallBackPtr cs_data_pipe_wait_callBack(CSDataPipeNative *dataPipe) {
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

int cs_data_pipe_wait_type(CSDataPipeNative *dataPipe) {
    //wait type determines
    while (dataPipe->_type == 0) {
        pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
        pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    }
    return dataPipe->_type;
    
}

void cs_data_pipe_process_pull(CSDataPipeNative *dataPipe) {
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

void cs_data_pipe_process_push(CSDataPipeNative *datapipe) {
    
}


static void* cs_data_pipe_thread_proc(void *param)
{
    CSDataPipeNative   *dataPipe = (CSDataPipeNative*)param;

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



CSDataPipeNative* cs_data_pipe_create(void) {
    CSDataPipeNative *dataPipe = NULL;
    // alloc dataPipe context
    dataPipe = (CSDataPipeNative*)calloc(1, sizeof(CSDataPipeNative));
    if (!dataPipe) return NULL;
    
    //init
    pthread_mutex_init(&dataPipe->_status_sync_mutex, NULL);
    pthread_cond_init(&dataPipe->_status_sync_cond, NULL);
    pthread_cond_init(&dataPipe->_params_sync_cond, NULL);
    pthread_create(&dataPipe->process_thread, NULL, cs_data_pipe_thread_proc, dataPipe);
    
    
    return dataPipe;
}

void cs_data_pipe_release(CSDataPipeNative* dataPipe) {
    free(dataPipe);
}

void cs_data_pipe_resume(CSDataPipeNative* dataPipe) {
    
}

void cs_data_pipe_pause(CSDataPipeNative* dataPipe) {
    
}

void cs_data_pipe_pull_data(CSDataPipeNative* dataPipe,PullCallBackPtr callback) {
    
}

//////////////////////////////////////////////////////////////////
///Data Processor


//Internal
void cs_process_unit_on_init(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    if (unit->_onIntFunc != NULL) {
        unit->_onIntFunc();
        unit->_status = unit->_status | CS_PU_STATUS_INIT;
    }
}

void cs_process_unit_process_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    for (int i = 0; i < unit->_dependentUnitCount; i++) {
        CSDataHeaderNative* dataHeader = unit->_dependentInputPtr[i];
        if(dataHeader->context_type == 0){
            CSDataSourceNative* childSource = (CSDataSourceNative*)dataHeader;
            cs_process_source_process(dataPipe, childSource);
        }else{
            CSProcessUnitNative* childUnit = (CSProcessUnitNative*)dataHeader;
            cs_process_unit_process(dataPipe, childUnit);
        }
    }
}


CSDataWrapNative* cs_process_unit_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    if(unit->_onProcessFunc != NULL){
        unit->_onProcessFunc();
    }
    return unit->_outputData;
}

CSDataWrapNative* cs_process_unit_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    
    //on init
    if (!(unit->_status & CS_PU_STATUS_INIT)){
        cs_process_unit_on_init(dataPipe, unit);
    }
    
    //on process
    cs_process_unit_process_dependent(dataPipe, unit);
    
    return cs_process_unit_on_process(dataPipe, unit);
}

CSDataWrapNative* cs_process_source_process(CSDataPipeNative *dataPipe,CSDataSourceNative *dataSource) {
    return NULL;
}


//Public
CSProcessUnitNative* cs_data_processor_create(void) {
    CSProcessUnitNative *processor = NULL;
    // alloc processor context
    processor = (CSProcessUnitNative*)calloc(1, sizeof(CSProcessUnitNative));
    if (!processor) return NULL;
    return processor;
}


void cs_data_processor_release(CSProcessUnitNative* processor) {
    free(processor);
}



void cs_data_processor_connect_source_dep(CSProcessUnitNative* processor,CSDataSourceNative *dep_dataSource) {
    processor->_dependentInputPtr[processor->_dependentUnitCount] = dep_dataSource;
    processor->_dependentUnitCount += 1;
}

void cs_data_processor_connect_processor_dep(CSProcessUnitNative* processor,CSProcessUnitNative *dep_processor) {
    processor->_dependentInputPtr[processor->_dependentUnitCount] = dep_processor;
    processor->_dependentUnitCount += 1;
}



//TODO Read index is actively add 1
CSDataWrapNative* cs_data_processor_get_input_data(CSProcessUnitNative *source,int inputIndex) {
    void* dependentInputItem = source->_dependentInputPtr[inputIndex];
    CSDataCacheNative* dataCache = (CSDataCacheNative*)dependentInputItem;
    return dataCache->_cacheBuffer[dataCache->_readIndex];
}



////////////////////////////////////////////////////////////////
///data source


CSDataSourceNative* cs_data_source_create(void) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)calloc(1, sizeof(CSDataSourceNative));
    if (!source) return NULL;
    return source;
}

void cs_data_source_release(CSDataSourceNative *source) {
    free(source);
}








////////////////////////////////////////////////////////////////
///data cache

void cs_data_cache_create_data_cache(void *source, int dataSize) {
    CSDataCacheNative* cache = (CSDataCacheNative*)source;
    cache->_cacheBuffer[0] = malloc(dataSize);
    cache->_cacheBuffer[1] = malloc(dataSize);
}

CSDataWrapNative* cs_data_cache_lock_data_cache(void *source) {
    CSDataCacheNative* cache = (CSDataCacheNative*)source;
    
    if(cache->_readIndex == cache->_writeIndex) {
        return cache->_cacheBuffer[cache->_writeIndex + 1];
    }
    
    return cache->_cacheBuffer[cache->_writeIndex];
    
}

void cs_data_cache_unlock_data_cache(void *source) {
    CSDataCacheNative* cache = (CSDataCacheNative*)source;
    cache->_writeIndex = (cache->_writeIndex + 1) % CACHE_BUFFER_MAX_SIZE;
}
