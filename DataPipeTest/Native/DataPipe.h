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

//define data callback function
typedef void (*PullCallBackPtr)(const char* id, CSDataWrapNative*);

typedef void (*PUInitCallBackPtr)(void);
typedef void (*PUProcessCallBackPtr)(void);



//data cache
typedef struct
{

    int                 _readIndex;
    int                 _writeIndex;
    
    #define             CACHE_BUFFER_MAX_SIZE        2
    void*               _cacheBuffer[CACHE_BUFFER_MAX_SIZE];
    
} CSDataCacheNative;


//data header
typedef struct
{

    CSDataCacheNative cache;
    int context_type;
    
} CSDataHeaderNative;



//input data source
typedef struct
{
    CSDataHeaderNative header;
    
} CSDataSourceNative;



//process unit
typedef struct
{
    CSDataHeaderNative header;
    
    #define CS_PU_STATUS_INIT    (1 << 0)  // process uint inited
    #define CONNECT_NODE_MAX        3
    int             _status;
    
    
    PUInitCallBackPtr           _onIntFunc;
    
    int                 _dependentUnitCount;
//    int                 _dependentSourceCount;
    
    PUProcessCallBackPtr _onProcessFunc;
    CSDataWrapNative*         _outputData;
    
    void**              _dependentInputPtr;

} CSProcessUnitNative;

typedef struct
{
    // thread
    #define CS_DP_STATUS_PAUSE    (1 << 0)  // datapipe pause
    #define CS_DP_STATUS_CLOSE      (1 << 1)  // datapipe close
    #define CS_DP_STATUS_RUNNING      (1 << 2)  // datapipe running
    int             _status;
    pthread_t       process_thread;
    
    
    #define CS_DP_TYPES_PUSH      (1 << 0)  // push type
    #define CS_DP_TYPES_PULL      (1 << 1)  // pull type
    int             _type;    // datapipe type
    
    
    PullCallBackPtr   _callback;
    
    pthread_mutex_t _status_sync_mutex;
    pthread_cond_t  _status_sync_cond;
    pthread_cond_t  _params_sync_cond;
    
    
    CSProcessUnitNative*  _outPutNode;
    
} CSDataPipeNative;





/**
 ==============================================================
 Data Pipe
 */


CSDataPipeNative* cs_data_pipe_create(void);
void cs_data_pipe_release(CSDataPipeNative* dataPipe);

void cs_data_pipe_resume(CSDataPipeNative* dataPipe);
void cs_data_pipe_pause(CSDataPipeNative* dataPipe);

// pull data from data pipe
void cs_data_pipe_pull_data(CSDataPipeNative* dataPipe,PullCallBackPtr callback);


/**
 ==============================================================
 */






/**
 ==============================================================
 Data Source
 */


//enum VIDEOPARAM
//{
//    VIDEO_HEIGHT=1,
//    VIDEO_WIDTH,
//    COLOR_SPACES
//} ;
//
//enum
//{
//    RGBA = 1,
//    BGRA,
//    NV21
//
//}ColorSpaces;
//
//
//typedef struct
//{
//    enum VIDEOPARAM param;
//    int value;
//
//} CSVideoParam;





CSDataSourceNative* cs_data_source_create(void);
void cs_data_source_release(CSDataSourceNative *source);


void cs_data_source_create_data_cache(CSDataSourceNative *source, int dataSize);
CSDataWrapNative* cs_data_source_lock_data_cache(CSDataSourceNative *source);
void cs_data_source_unlock_data_cache(CSDataSourceNative *source, CSDataWrapNative* dataWrap);


/**
 ==============================================================
 */








/**
 ==============================================================
 Data Processor
 */


CSProcessUnitNative* cs_data_processor_create(void);
void cs_data_processor_release(CSProcessUnitNative* processor);

CSDataWrapNative* cs_process_unit_process(CSDataPipeNative *dataPipe,CSProcessUnitNative* unit);
CSDataWrapNative* cs_process_source_process(CSDataPipeNative *dataPipe,CSDataSourceNative *dataSource);

CSDataWrapNative* cs_data_processor_get_input_data(CSProcessUnitNative *source,int inputIndex);


/**
 ==============================================================
 */


#endif /* DataPipe_h */
