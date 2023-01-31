//
//  DataPipe.h
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

#ifndef DataPipe_h
#define DataPipe_h

#include <stdio.h>
#include <pthread.h>


typedef struct
{
    void* data;
    int dataSize;
    
} CSDataWrapNative;

//Define data callback function
typedef void (*PullCallBackPtr)(const char* id, CSDataWrapNative*);

typedef void (*PUInitCallBackPtr)(const void* swiftObjPtr);
typedef void (*PUReleaseCallBackPtr)(const void* swiftObjPtr);
typedef void (*PUProcessCallBackPtr)(const void* swiftObjPtr);



//Data cache
typedef struct
{

    int                 _readIndex;
    int                 _writeIndex;
    
    #define             CACHE_BUFFER_MAX_SIZE        2
    void*               _cacheBuffer[CACHE_BUFFER_MAX_SIZE];
    
} CSDataCacheNative;


//Data header
typedef struct
{

    CSDataCacheNative cache;
    //Context type
    #define CS_TYPE_SOURCE          (1 << 0)
    #define CS_TYPE_PROCESSOR       (1 << 1)
    int context_type;
    
    //Register function
    PUInitCallBackPtr               _onIntFunc;
    PUReleaseCallBackPtr            _onReleaseFunc;
    
    //Status sync
    #define CS_STATUS_INIT    (1 << 0)  // process uint inited
    int             _status;
    
    
    const void*           _bindingSwiftObject;
} CSDataHeaderNative;



//Input data source
typedef struct
{
    CSDataHeaderNative              header;
} CSDataSourceNative;



//Process unit
typedef struct
{
    CSDataHeaderNative header;
    
    //Register function
    PUProcessCallBackPtr        _onProcessFunc;
    
    //Dependent unit
    int                 _dependentUnitCount;
    void**              _dependentInputPtr;

    
    #define CONNECT_NODE_MAX        3
    

} CSProcessUnitNative;

typedef struct
{
    // Thread
    #define CS_DP_STATUS_PAUSE    (1 << 0)  // datapipe pause
    #define CS_DP_STATUS_CLOSE      (1 << 1)  // datapipe close
    #define CS_DP_STATUS_RUNNING      (1 << 2)  // datapipe running
    #define CS_DP_STATUS_VSYNC      (1 << 3)  // datapipe vsync
    int             _status;
    pthread_t       process_thread;
    
    
    #define CS_DP_TYPES_PUSH      (1 << 0)  // push type
    #define CS_DP_TYPES_PULL      (1 << 1)  // pull type
    int             _type;    // datapipe type
    
    
    PullCallBackPtr   _callback;
    
    pthread_mutex_t _status_sync_mutex;
    pthread_cond_t  _status_sync_cond;
//    pthread_cond_t  _params_sync_cond;
    
    
    CSProcessUnitNative*  _outPutNode;
    
} CSDataPipeNative;
































/**
 ==============================================================
 Data Pipe
 */


//init
void* cs_data_pipe_create();
void cs_data_pipe_release(void* dataPipePtr);


//contorl
void cs_data_pipe_pause(void* dataPipePtr);
void cs_data_pipe_resume(void* dataPipePtr);


// Receiver data from data pipe
void cs_data_pipe_register_receiver(void* dataPipePtr,PullCallBackPtr callback);


/**
 ==============================================================
 */



/**
 ==============================================================
 Data Cache
 */

void cs_data_cache_create_data_cache(void *sourcePtr, int dataSize);
CSDataWrapNative* cs_data_cache_lock_data_cache(void *sourcePtr);
void cs_data_cache_unlock_data_cache(void *sourcePtr);



/**
 ==============================================================
 */




/**
 ==============================================================
 Data Source
 */

void* cs_data_source_create(void);
void cs_data_source_release(void *sourcePtr);


void cs_data_header_binding(void* sourcePtr, const void* swiftObjPtr);
void cs_data_source_register_onInit_function(void* sourcePtr, PUInitCallBackPtr callBack);
void cs_data_source_register_onRelease_function(void* sourcePtr, PUReleaseCallBackPtr callBack);


/**
 ==============================================================
 */








/**
 ==============================================================
 Data Processor
 */

//Create and release
void* cs_data_processor_create(void);
void cs_data_processor_release(void* processorPtr);


//Connect
void cs_data_processor_connect_dep(void* processorPtr,void* depPtr);

//Data
CSDataWrapNative* cs_data_processor_get_input_data(void* processorPtr,int inputIndex);

void cs_data_processor_register_onProcess_function(void* sourcePtr, PUProcessCallBackPtr callBack);
/**
 ==============================================================
 */


#endif /* DataPipe_h */
