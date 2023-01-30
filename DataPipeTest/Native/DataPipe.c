//
//  DataPipe.c
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

#include "DataPipe.h"
#include "DataPipe_Internal.h"
#include <stdlib.h>


//////////////////////////////////////////////////////////////////
///Data Processor
///


///Internal
int cs_data_pipe_wait_running(CSDataPipeNative *dataPipe) {
    //Wait type determines
    int result = 0;
    
    while ( !(result = dataPipe->_status & CS_DP_STATUS_RUNNING) ) {
        pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
        pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    }
    return result;
}

//TODO Use asynchronous locks first, and optimize to sleep() later
int cs_data_pipe_wari_vsync_frequency(CSDataPipeNative *dataPipe) {
    int result = dataPipe->_status & CS_DP_STATUS_VSYNC;
    if (result) return result;
    
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    if (!(dataPipe->_status & CS_DP_STATUS_VSYNC)){
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
    }
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    
    result = dataPipe->_status & CS_DP_STATUS_VSYNC;
    return result;
}


void cs_data_pipe_process(CSDataPipeNative *dataPipe) {
    
    CSProcessUnitNative* endProcessor = dataPipe->_outPutNode;
    cs_processor_process(dataPipe, endProcessor);
    

    PullCallBackPtr callBack = dataPipe->_callback;
    if(callBack != NULL) {
        CSDataWrapNative* dataWrap = cs_data_cache_lock_data_cache(endProcessor);
        callBack("1",dataWrap);
        cs_data_cache_unlock_data_cache(dataPipe);
    }
}





static void* cs_data_pipe_thread_proc(void *param)
{
    CSDataPipeNative *dataPipe = (CSDataPipeNative*)param;

    // #1 Whether is over for each round
    while (!(dataPipe->_status & CS_DP_STATUS_CLOSE)) {
        
        //Determines runing mode
        if (!cs_data_pipe_wait_running(dataPipe)){
            continue;
        }
        
        //Determine Vsync frequency
        if (!cs_data_pipe_wari_vsync_frequency(dataPipe)){
            continue;
        }
        
        
        cs_data_pipe_process(dataPipe);
    }
    return NULL;
}



///Public

void* cs_data_pipe_create(void) {
    CSDataPipeNative *dataPipe = NULL;
    // Alloc dataPipe context
    dataPipe = (CSDataPipeNative*)calloc(1, sizeof(CSDataPipeNative));
    if (!dataPipe) return NULL;
    
    //Init
    pthread_mutex_init(&dataPipe->_status_sync_mutex, NULL);
    pthread_cond_init(&dataPipe->_status_sync_cond, NULL);
    pthread_cond_init(&dataPipe->_params_sync_cond, NULL);
    pthread_create(&dataPipe->process_thread, NULL, cs_data_pipe_thread_proc, dataPipe);
    
    
    return dataPipe;
}

void cs_data_pipe_release(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    free(dataPipe);
}


void cs_data_pipe_pause(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    dataPipe->_status |= ~CS_DP_STATUS_RUNNING;
}

void cs_data_pipe_resume(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    if(dataPipe->_status & CS_DP_STATUS_RUNNING) return;
    
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    if(!(dataPipe->_status & CS_DP_STATUS_RUNNING)){
        dataPipe->_status |=  CS_DP_STATUS_RUNNING;
        pthread_cond_signal(&(dataPipe->_status_sync_cond));
    }
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
}


//void cs_data_pipe_pull_data(CSDataPipeNative* dataPipe,PullCallBackPtr callback) {
//    if (callback == NULL){
//        //Pause data pipe
//
//        return;
//    }
//}

void cs_data_pipe_register_receiver(void* dataPipePtr,PullCallBackPtr callback) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    dataPipe->_callback = callback;
}

//////////////////////////////////////////////////////////////////
///Data Processor


//Internal

void cs_processor_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    if(unit->_onProcessFunc != NULL){
        unit->_onProcessFunc();
    }
}

void cs_processor_process_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    // Load Dependent
    for (int i = 0; i < unit->_dependentUnitCount; i++) {
        CSDataHeaderNative* dataHeader = unit->_dependentInputPtr[i];
        
        //5.Processor continue loading dependencies
        if(dataHeader->context_type == CS_TYPE_PROCESSOR){
            CSProcessUnitNative* childUnit = (CSProcessUnitNative*)dataHeader;
            cs_processor_process_dependent(dataPipe, childUnit);
        }
    }
    
    //Handle Process
    cs_processor_on_process(dataPipe,unit);
}


//8. Load Init Function
void cs_header_process_init(CSDataPipeNative *dataPipe, CSDataHeaderNative* header) {
    if (header->_onIntFunc != NULL) {
        header->_onIntFunc(NULL);
    }
    header->_status = header->_status | CS_STATUS_INIT;
}

//2. Loading Init dependencies
void cs_processor_init_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    CSDataHeaderNative *header = (CSDataHeaderNative*)unit;
    
    //3. If loaded Init,then return
    if ((header->_status & CS_STATUS_INIT)){
        return;
    }
    
    //4. Load Dependent
    for (int i = 0; i < unit->_dependentUnitCount; i++) {
        CSDataHeaderNative* dataHeader = unit->_dependentInputPtr[i];
        
        //5.Processor continue loading dependencies
        if(dataHeader->context_type == CS_TYPE_PROCESSOR){
            CSProcessUnitNative* childUnit = (CSProcessUnitNative*)dataHeader;
            cs_processor_process_dependent(dataPipe, childUnit);
        }else{
            //6.Source load init
            cs_header_process_init(dataPipe, dataHeader);
        }
    }
    
    //7. Load init for self
    cs_header_process_init(dataPipe, (CSDataHeaderNative*)unit);
}


// 1.
void cs_processor_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    //Load Init Dependent
    cs_processor_init_dependent(dataPipe, unit);
    
    //Load Process Dependent
    cs_processor_process_dependent(dataPipe, unit);
}








//Public
void* cs_data_processor_create(void) {
    CSProcessUnitNative *processor = NULL;
    // Alloc processor context
    processor = (CSProcessUnitNative*)calloc(1, sizeof(CSProcessUnitNative));
    if (!processor) return NULL;
    return processor;
}


void cs_data_processor_release(void* processorPtr) {
    CSDataPipeNative *processor = (CSDataPipeNative *)processorPtr;
    if(!processor) return;
    
    free(processor);
}



void cs_data_processor_connect_dep(void* processorPtr,void *depPtr) {
    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
    if(!processor) return;
    
    CSDataHeaderNative *dependentUnit = (CSDataHeaderNative *)depPtr;
    if(!dependentUnit) return;
    
    
    processor->_dependentInputPtr[processor->_dependentUnitCount] = dependentUnit;
    processor->_dependentUnitCount += 1;
}





//TODO Read index is actively add 1
CSDataWrapNative* cs_data_processor_get_input_data(void* processorPtr,int inputIndex) {
    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
    if(!processor) return NULL;
    
    void* dependentUnit = processor->_dependentInputPtr[inputIndex];
    CSDataCacheNative* dataCache = (CSDataCacheNative*)dependentUnit;
    if(!dataCache) return NULL;
    
    return dataCache->_cacheBuffer[dataCache->_readIndex];
}



////////////////////////////////////////////////////////////////
///Data source


void* cs_data_source_create(void) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)calloc(1, sizeof(CSDataSourceNative));
    if (!source) return NULL;
    return source;
}

void cs_data_source_release(void *sourcePtr) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)calloc(1, sizeof(CSDataSourceNative));
    if (!source) return;
    
    free(source);
}


void cs_data_source_register_onInit_function(void* sourcePtr, PUInitCallBackPtr callBack) {
    CSDataHeaderNative *source = NULL;
    source = (CSDataHeaderNative*)calloc(1, sizeof(CSDataHeaderNative));
    if (!source) return;
    
    source->_onIntFunc = callBack;
}

void cs_data_source_register_onRelease_function(void* sourcePtr, PUReleaseCallBackPtr callBack) {
    CSDataHeaderNative *source = NULL;
    source = (CSDataHeaderNative*)calloc(1, sizeof(CSDataHeaderNative));
    if (!source) return;
    
    source->_onReleaseFunc = callBack;
}




////////////////////////////////////////////////////////////////
///Data cache

void cs_data_cache_create_data_cache(void *sourcePtr, int dataSize) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    cache->_cacheBuffer[0] = malloc(dataSize);
    cache->_cacheBuffer[1] = malloc(dataSize);
}

CSDataWrapNative* cs_data_cache_lock_data_cache(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    
    if(cache->_readIndex == cache->_writeIndex) {
        return cache->_cacheBuffer[cache->_writeIndex + 1];
    }
    
    return cache->_cacheBuffer[cache->_writeIndex];
    
}

void cs_data_cache_unlock_data_cache(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    cache->_writeIndex = (cache->_writeIndex + 1) % CACHE_BUFFER_MAX_SIZE;
}
