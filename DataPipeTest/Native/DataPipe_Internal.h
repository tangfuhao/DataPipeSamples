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


void cs_header_process_init(CSDataPipeNative *dataPipe, CSDataHeaderNative* header);

void cs_processor_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);
void cs_processor_process_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);

void cs_processor_init_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);
void cs_processor_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);


/**
 ==============================================================
 */



#endif /* DataPipe_Internal_h */
