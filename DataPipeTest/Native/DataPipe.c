//
//  DataPipe.c
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

#include "DataPipe.h"
#include "DataPipe_Internal.h"
#include <stdlib.h>
#include <string.h>


//////////////////////////////////////////////////////////////////
///Data Processor
///

static int InstanceCount = 0;


///Internal
int cs_data_pipe_wait_running(CSDataPipeNative *dataPipe) {
    //Wait type determines
    int result = dataPipe->_status & CS_DP_STATUS_RUNNING;
    if (result) return result;
    
    
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    if (!(dataPipe->_status & CS_DP_STATUS_RUNNING)){
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
    }
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));

    if(dataPipe->_status & CS_DP_STATUS_CLOSE){
        return 0;
    }else{
        return dataPipe->_status & CS_DP_STATUS_RUNNING;
    }
    return result;
}

//TODO Use asynchronous locks first, and optimize to sleep() later
int cs_data_pipe_wari_vsync_frequency(CSDataPipeNative *dataPipe) {
    int result = dataPipe->_status & CS_DP_STATUS_VSYNC;
    if (result) return result;
    
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    if (!(result = (dataPipe->_status & CS_DP_STATUS_VSYNC))){
        pthread_cond_wait(&(dataPipe->_status_sync_cond), &(dataPipe->_status_sync_mutex));
    }
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    
    result = dataPipe->_status & CS_DP_STATUS_VSYNC;
    dataPipe->_status &= (~CS_DP_STATUS_VSYNC);
    
    if(dataPipe->_status & CS_DP_STATUS_CLOSE){
        return 0;
    }else{
        return result;
    }
    
}


void cs_data_pipe_process(CSDataPipeNative *dataPipe) {
    
    //TODO: Consider _outPutNode do not setting situation
    CSProcessUnitNative* endProcessor = dataPipe->_outPutNode;
    if(endProcessor == NULL) return;
    cs_processor_process(dataPipe, endProcessor);
    

    PullCallBackPtr callBack = dataPipe->_callback;
    if(callBack != NULL) {
        CSDataWrapNative* dataWrap = cs_data_cache_read_data_cache(endProcessor);
        callBack(dataPipe->_bindingWrapperObject,dataWrap);
    }
}





static void* cs_data_pipe_thread_proc(void *param)
{
    CSDataPipeNative *dataPipe = (CSDataPipeNative*)param;
    printf("thread open \n");
    InstanceCount++;

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
    
    InstanceCount--;
    
    printf("thread close \n");
    return NULL;
}



void cs_operate_release(CSDataHeaderNative* node) {
    if(node->context_type == CS_TYPE_PROCESSOR){
        CSProcessUnitNative* processor = (CSProcessUnitNative*)node;
        cs_data_pipe_iterate_topology_node(processor,cs_operate_release);
        cs_data_processor_release_internal(processor);
    }else{
        CSDataSourceNative* source = (CSDataSourceNative*)node;
        cs_data_source_release_internal(source);
    }
}

void cs_data_pipe_iterate_topology_node(CSProcessUnitNative* node, void (*operateFunc)(CSDataHeaderNative* node)) {
    if(!node) return;
    
    for (int i = 0; i < node->_dependentUnitCount; i++) {
        CSDataHeaderNative* dataHeader = node->_dependentInputPtr[i];
        operateFunc(dataHeader);
    }
}


void cs_data_pipe_stop(CSDataPipeNative *dataPipe) {
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    dataPipe->_status |= CS_DP_STATUS_CLOSE;
    pthread_cond_signal(&(dataPipe->_status_sync_cond));
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    
    pthread_join(dataPipe->process_thread, NULL);
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
//    pthread_cond_init(&dataPipe->_params_sync_cond, NULL);
    pthread_create(&dataPipe->process_thread, NULL, cs_data_pipe_thread_proc, dataPipe);
    
    
    return dataPipe;
}




void cs_data_pipe_release(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    
    cs_data_pipe_stop(dataPipe);
    
    cs_data_pipe_iterate_topology_node(dataPipe->_outPutNode,cs_operate_release);
    cs_data_processor_release_internal(dataPipe->_outPutNode);
    free(dataPipe);
}

void cs_data_pipe_binding(void* dataPipePtr, const void* wrapperObject) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    dataPipe->_bindingWrapperObject = wrapperObject;
}


void cs_data_pipe_set_main_source(void* dataPipePtr,void* sourcePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    CSDataHeaderNative *source = (CSDataHeaderNative *)sourcePtr;
    if(!source) return;
    
    
    cs_header_process_init(dataPipe,source);
    
}

void cs_data_pipe_set_output_node(void* dataPipePtr,void* processorPtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    
    CSDataHeaderNative *source = (CSDataHeaderNative *)processorPtr;
    if(!source) return;
    
    dataPipe->_outPutNode = processorPtr;
    cs_header_process_init(dataPipe,source);
}


//CSDataCategoryNative cs_data_pipe_get_out_put_data_type(void* dataPipePtr) {
//    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
//    if(!dataPipe) return 0;
//    
//    CSProcessUnitNative* unitNode = dataPipe->_outPutNode;
//    if(!unitNode) return 0;
//    
//    return unitNode->header.cache._cache_data_params._data_type;
//}


void* cs_data_pipe_get_out_put_node(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return NULL;
    
    CSProcessUnitNative* unitNode = dataPipe->_outPutNode;
    if(!unitNode) return NULL;
    
    return unitNode;
}

void cs_data_pipe_vsync(void* dataPipePtr) {
    CSDataPipeNative *dataPipe = (CSDataPipeNative *)dataPipePtr;
    if(!dataPipe) return;
    
    if (dataPipe->_status & CS_DP_STATUS_VSYNC) return;
    
    pthread_mutex_lock(&(dataPipe->_status_sync_mutex));
    if (!(dataPipe->_status & CS_DP_STATUS_VSYNC)){
        dataPipe->_status |= CS_DP_STATUS_VSYNC;
        pthread_cond_signal(&(dataPipe->_status_sync_cond));
    }
    pthread_mutex_unlock(&(dataPipe->_status_sync_mutex));
    
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
    
    if(callback){
        dataPipe->_callback = callback;
        cs_data_pipe_resume(dataPipe);
    }else{
        cs_data_pipe_pause(dataPipe);
    }
    
    
}

//////////////////////////////////////////////////////////////////
///Data Processor


//Internal

void cs_processor_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    if(unit->_onProcessFunc != NULL){
        unit->_onProcessFunc(unit->header._bindingWrapperObject);
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
        header->_onIntFunc(header->_bindingWrapperObject);
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


void cs_operate_add_read_index(CSDataHeaderNative* node) {
    
    if(node->cache._readed){
        node->cache._readed = 0;
        node->cache._readIndex = (node->cache._readIndex + 1) % CACHE_BUFFER_MAX_SIZE;
    }
    
    if(node->context_type == CS_TYPE_PROCESSOR){
        CSProcessUnitNative* processor = (CSProcessUnitNative*)node;
        cs_data_pipe_iterate_topology_node(processor,cs_operate_release);
    }
}

//TODO: consider muti read sisuation ,create index var for every pipe
//add 1 to all read index
void cs_processor_cache_buffer_index_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    cs_data_pipe_iterate_topology_node(unit,cs_operate_add_read_index);
    
    if(unit->header.cache._readed){
        unit->header.cache._readed = 0;
        unit->header.cache._readIndex = (unit->header.cache._readIndex + 1) % CACHE_BUFFER_MAX_SIZE;
    }
}


// 1.
void cs_processor_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit) {
    //Load Init Dependent
    cs_processor_init_dependent(dataPipe, unit);
    
    //Load Process Dependent
    cs_processor_process_dependent(dataPipe, unit);
    
    //Load Add 1 Dependent
    cs_processor_cache_buffer_index_dependent(dataPipe, unit);
}







void cs_data_processor_release_internal(CSProcessUnitNative* processor) {
    if(!processor) return;
    if(processor->header._onReleaseFunc){
        processor->header._onReleaseFunc(processor->header._bindingWrapperObject);
    }
}

//Public
void* cs_data_processor_create(void) {
    CSProcessUnitNative *processor = NULL;
    // Alloc processor context
    processor = (CSProcessUnitNative*)calloc(1, sizeof(CSProcessUnitNative));
    processor->header.cache._writeIndex = 1;
    processor->header.context_type = CS_TYPE_PROCESSOR;
    if (!processor) return NULL;
    return processor;
}

void cs_data_processor_release(void* processorPtr){
    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
    if(!processor) return;
    free(processor);
}




void cs_data_processor_connect_dep(void* processorPtr,void *depPtr) {
    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
    if(!processor) return;
    
    CSDataHeaderNative *dependentUnit = (CSDataHeaderNative *)depPtr;
    if(!dependentUnit) return;
    
    
//    if(processor->_dependentInputPtr == NULL) {
//        processor->_dependentInputPtr = malloc(sizeof(void*) * (processor->_dependentUnitCount + 1));
//    }else{
//        void* tempZone = malloc(sizeof(void*) * processor->_dependentUnitCount);
//        void* srcPtr = processor->_dependentInputPtr;
//        int copySize = sizeof(void*) * processor->_dependentUnitCount;
//        memcpy(tempZone, srcPtr, copySize);
//        processor->_dependentInputPtr = tempZone;
//        free(srcPtr);
//    }
    
    processor->_dependentInputPtr[processor->_dependentUnitCount] = dependentUnit;
    processor->_dependentUnitCount += 1;
    
}


//TODO: Read index is actively add 1
//CSDataWrapNative* cs_data_processor_get_input_data(void* processorPtr,int inputIndex) {
//    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
//    if(!processor) return NULL;
//    
//    void* dependentUnit = processor->_dependentInputPtr[inputIndex];
//    CSDataCacheNative* dataCache = (CSDataCacheNative*)dependentUnit;
//    if(!dataCache) return NULL;
//    
//    return cs_data_cache_read_data_cache(dataCache);
//}


void* cs_data_processor_get_input_node(void* processorPtr,int inputIndex) {
    CSProcessUnitNative *processor = (CSProcessUnitNative *)processorPtr;
    if(!processor) return NULL;
    
    void* dependentUnit = processor->_dependentInputPtr[inputIndex];
    CSDataCacheNative* dataCache = (CSDataCacheNative*)dependentUnit;
    if(!dataCache) return NULL;
    
    return dataCache;
}

void cs_data_processor_register_onProcess_function(void* sourcePtr, PUProcessCallBackPtr callBack) {
    CSProcessUnitNative *processor = NULL;
    processor = (CSProcessUnitNative*)sourcePtr;
    if (!processor) return;
    
    processor->_onProcessFunc = callBack;
}



////////////////////////////////////////////////////////////////
///Data source


void* cs_data_source_create(void) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)calloc(1, sizeof(CSDataSourceNative));
    source->header.cache._writeIndex = 1;
    source->header.context_type = CS_TYPE_SOURCE;
    if (!source) return NULL;
    
    return source;
}

void cs_data_source_release(void *sourcePtr){
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)sourcePtr;
    if (!source) return;
    free(source);
}



void cs_data_source_release_internal(CSDataSourceNative *source) {
    if (!source) return;
    
    if(source->header._onReleaseFunc){
        source->header._onReleaseFunc(source->header._bindingWrapperObject);
    }
}


void cs_data_source_register_onInit_function(void* sourcePtr, PUInitCallBackPtr callBack) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)sourcePtr;
    if (!source) return;
    
    source->header._onIntFunc = callBack;
}

void cs_data_source_register_onRelease_function(void* sourcePtr, PUReleaseCallBackPtr callBack) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)sourcePtr;
    if (!source) return;
    
    source->header._onReleaseFunc = callBack;
}

void cs_data_header_binding(void *sourcePtr, const void* wrapperObjPtr) {
    CSDataSourceNative *source = NULL;
    source = (CSDataSourceNative*)sourcePtr;
    if (!source) return;
    
    source->header._bindingWrapperObject = wrapperObjPtr;
}




////////////////////////////////////////////////////////////////
///Data cache
///

void cs_data_cache_create_data_cache(void *sourcePtr, int dataSize, CSDataCategoryNative dataCategory) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return;
    cache->_cache_data_params._data_type = dataCategory;
    
    for (int i = 0; i < CACHE_BUFFER_MAX_SIZE; i++) {
        CSDataWrapNative* dataWrap = calloc(1, sizeof(CSDataWrapNative));
        dataWrap->dataSize = dataSize;
        dataWrap->data = malloc(dataSize);
        
        cache->_cacheBuffer[i] = dataWrap;
    }
}

int cs_get_bytes_per_row(int width, CSDataCategoryNative category) {
    if (category == NV21){
        return width + (width >> 1) + 4;
    }
    
    return width << 2;
}

void cs_data_cache_create_video_data_cache(void *sourcePtr, int width, int height, CSDataCategoryNative dataCategory) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return;
    cache->_cache_data_params._data_type = dataCategory;
    

    int bytesPerRow = cs_get_bytes_per_row(width, dataCategory);
    cache->_cache_data_params._params.videoParams.width = width;
    cache->_cache_data_params._params.videoParams.bytesPerRow = bytesPerRow;
    
    for (int i = 0; i < CACHE_BUFFER_MAX_SIZE; i++) {
        CSDataWrapNative* dataWrap = calloc(1, sizeof(CSDataWrapNative));
        
        int dataSize = height * bytesPerRow;
        
        dataWrap->dataSize = dataSize;
        dataWrap->data = malloc(dataSize);
        cache->_cacheBuffer[i] = dataWrap;
    }
}


CSDataCategoryNative cs_data_cache_get_data_category(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return BIN;
    
    return cache->_cache_data_params._data_type;
}

int cs_data_cache_get_bytes_per_row(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return 0;
    if (cache->_cache_data_params._data_type < RGBA32) return 0;
    
    return cache->_cache_data_params._params.videoParams.bytesPerRow;
}

int cs_data_cache_get_width(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return 0;
    if (cache->_cache_data_params._data_type < RGBA32) return 0;
    
    return cache->_cache_data_params._params.videoParams.width;
}

CSDataWrapNative* cs_data_cache_lock_data_cache(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return NULL;

    return cache->_cacheBuffer[cache->_writeIndex];
    
}

void cs_data_cache_unlock_data_cache(void *sourcePtr) {
    CSDataCacheNative* cache = (CSDataCacheNative*)sourcePtr;
    if(!cache) return ;
    
//    printf("%p 写:%d \n",sourcePtr,cache->_writeIndex);
    
    CSDataHeaderNative* sasdasd = (CSDataHeaderNative*)sourcePtr;
    
    if(sasdasd->context_type == CS_TYPE_PROCESSOR){
        cache->_writeIndex = (cache->_writeIndex + 1) % CACHE_BUFFER_MAX_SIZE;
    }else{
        cache->_writeIndex = (cache->_writeIndex + 1) % CACHE_BUFFER_MAX_SIZE;
    }
}

CSDataWrapNative* cs_data_cache_read_data_cache(void *sourcePtr) {
    CSDataCacheNative* dataCache = (CSDataCacheNative*)sourcePtr;
    if(!dataCache) return NULL;
    
    
    
//    printf("%p 欲读:%d \n",sourcePtr,dataCache->_readIndex);
    
    if(dataCache->_readIndex == dataCache->_writeIndex){
        if(dataCache->_writeIndex == 0){
            dataCache->_readIndex = CACHE_BUFFER_MAX_SIZE - 1;
        }else{
            dataCache->_readIndex = dataCache->_writeIndex - 1;
        }
    }
    //mark readed
    dataCache->_readed = 1;
//    printf("%p 实际读:%d \n",sourcePtr,dataCache->_readIndex);
    return dataCache->_cacheBuffer[dataCache->_readIndex];
}
