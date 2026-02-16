#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"

#define BYTE uint8_t

DLLEXPORT mint WolframLibrary_getVersion() {
    return WolframLibraryVersion;
}

DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
    return LIBRARY_NO_ERROR;
}

DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData) {
    return;
}

DLLEXPORT int byteMask(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    MNumericArray nArr = MArgument_getMNumericArray(Args[0]);
    BYTE* arr = (BYTE *)libData->numericarrayLibraryFunctions->MNumericArray_getData(nArr); 
    mint arrLen = MArgument_getInteger(Args[1]);
    MNumericArray nMask = MArgument_getMNumericArray(Args[2]);
    BYTE* mask = (BYTE *)libData->numericarrayLibraryFunctions->MNumericArray_getData(nMask);
    mint maskLen = MArgument_getInteger(Args[3]);

    MNumericArray nResult;
    libData->numericarrayLibraryFunctions->MNumericArray_new(MNumericArray_Type_UBit8, 1, &arrLen, &nResult);
    BYTE *result = (BYTE*)libData->numericarrayLibraryFunctions->MNumericArray_getData(nResult); 

    const int len = arrLen - arrLen % maskLen; 
    int k; 

    for (size_t i = 0; i < len; i = i + maskLen)
    {
        for (size_t j = 0; j < maskLen; j++){
            k = i + j; 
            result[k] = arr[k] ^ mask[j]; 
        }
    }

    for (size_t i = len; i < arrLen; i++)
    {
        result[i] = arr[i] ^ mask[i % maskLen];
    }
    

    MArgument_setMNumericArray(Res, nResult);
    return LIBRARY_NO_ERROR;
}
