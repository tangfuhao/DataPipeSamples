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

void cs_process_unit_on_init(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);
void cs_process_unit_process_dependent(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);

CSDataWrapNative* cs_process_unit_on_process(CSDataPipeNative *dataPipe, CSProcessUnitNative* unit);

CSDataWrapNative* cs_process_unit_process(CSDataPipeNative *dataPipe,CSProcessUnitNative* unit);
CSDataWrapNative* cs_process_source_process(CSDataPipeNative *dataPipe,CSDataSourceNative *dataSource);

/**
 ==============================================================
 */



#endif /* DataPipe_Internal_h */
