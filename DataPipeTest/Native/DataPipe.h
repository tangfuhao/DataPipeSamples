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
    
} CSDataWrap;

//define data callback function
typedef void (*PullCallBackPtr)(CSDataWrap*);

typedef void (*PUInitCallBackPtr)(void);
typedef void (*PUProcessCallBackPtr)(void);




//input data source
typedef struct
{
    int a;
    char b;
    double c;
} CSDataSource;



//process unit
typedef struct
{
    #define CS_PU_STATUS_INIT    (1 << 0)  // process uint inited
    #define CONNECT_NODE_MAX        3
    int             _status;
    
    
    PUInitCallBackPtr           _onIntFunc;
    
    int                 _dependentUnitCount;
    int                 _dependentSourceCount;
    
    PUProcessCallBackPtr _onProcessFunc;
    CSDataWrap*         _outputData;
    
    void*              _dependentUnitPtr[CONNECT_NODE_MAX];
    void*              _dependentSourcePtr[CONNECT_NODE_MAX];
} CSProcessUnit;

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
    
    
    CSProcessUnit*  _outPutNode;
    
} CSDataPipe;







CSDataPipe* cs_data_pipe_create(void);
void cs_data_pipe_release(CSDataPipe* dataPipe);



void cs_data_pipe_resume(CSDataPipe* dataPipe);
void cs_data_pipe_pause(CSDataPipe* dataPipe);

// pull data from data pipe
void cs_data_pipe_pull_data(CSDataPipe* dataPipe,PullCallBackPtr callback);



CSDataSource* cs_data_source_create(void);
void cs_data_source_release(CSDataSource *source);


CSDataWrap* cs_process_unit_process(CSDataPipe *dataPipe,CSProcessUnit* unit);

CSDataWrap* cs_process_source_process(CSDataPipe *dataPipe,CSDataSource *dataSource);


#endif /* DataPipe_h */
