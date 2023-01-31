//
//  DataPipe_Internal.h
//  DataPipeTest
//
//  Created by fuhao on 2023/1/30.
//

#ifndef DataPipe_Internal_h
#define DataPipe_Internal_h



/**
 ==============================================================
 Data Processor
 */


void cs_data_pipe_release_all_unit(CSDataPipeNative* dataPipe);
void cs_data_pipe_stop(CSDataPipeNative *dataPipe);

void cs_header_process_init(CSDataPipeNative *dataPipe, CSDataHeaderNative* header);

void cs_processor_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);
void cs_processor_process_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);

void cs_processor_init_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);
void cs_processor_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);


void cs_data_processor_release_internal(CSProcessUnitNative* processor);
void cs_data_source_release_internal(CSDataSourceNative* source);


void cs_operate_release(CSDataHeaderNative* node) ;
void cs_data_pipe_iterate_topology_node(CSProcessUnitNative* node, void (*operateFunc)(CSDataHeaderNative* node)) ;

/**
 ==============================================================
 */



#endif /* DataPipe_Internal_h */
