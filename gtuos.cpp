#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <string.h>
#include <fstream> 

using namespace std;

#define CYCLE 10

GTUOS::GTUOS(){
  //string inputFile = "input.txt";
  //string outputFile = "output.txt";  

  /*open files*/
  //cin.open(inputFile);
  //cout.open(outputFile);  
}

GTUOS::~GTUOS(){
  /*close files*/
  //cin.close();
  //cout.close();  
}

/*
  Handle the operating system calls
*/
uint64_t GTUOS::handleCall(CPU8080& cpu){
  //cout << "system" << endl;
  uint16_t cycles;

  int c = 0;
  if(1 || (cin && cout)){
    switch(cpu.state->a){
    case PRINT_B:
      cycles = sysPrintB(cpu);
      break;
    case PRINT_MEM:
      cycles = sysPrintMem(cpu);    
      break;
    case READ_B:
      cycles = sysReadB(cpu);
      break;
    case READ_MEM:
      cycles = sysReadMem(cpu);
      break;
    case PRINT_STR:
      cycles = sysPrintStr(cpu);
      break;
    case READ_STR:
      cycles = sysReadStr(cpu);
      break;
    case LOAD_EXEC:
      cycles = loadExec(cpu);
      break;
    case PROCESS_EXIT:
      cycles = processExit(cpu);
      break;
    case SET_QUANTUM:
            break;
    case PRINT_WHOLE:
      cycles = printWhole(cpu);
      break;
    case 11:      

       for(int i = 0 ; i < 0x10000 ; ++i){
      // for(int i = 53248 ; i < 53280 ; ++i){
	if(i % 32 == 0){
	  printf("\n");
	  printf("%d - ",c++);
	}

	printf("%3d ",cpu.memory->at(i));
      }
      printf("\n");
      break;
    default:

      break;
    }
  }else{
    cout << "Not found input.txt or output.txt" << endl;
  }
  return cycles;
}
/*
 * Called when scheduling happened
 * Prints PID,PC,MEM_BASE Content and Address,SP
 **/
uint64_t GTUOS::printWhole(CPU8080& cpu){
  uint16_t lastProcess = 0x00cffe;
  uint16_t ptableStart = 0x0d000;
  uint16_t ptableLen = 0x00100;

  uint16_t ptableAddr = ptableStart;
  uint8_t pid = cpu.memory->at(lastProcess);

  uint8_t tempPid = pid;
  while(tempPid > 0){
    ptableAddr += ptableLen;
    tempPid--;
  }
  uint16_t pc = (cpu.memory->at(ptableAddr + 10) << 8) | cpu.memory->at(ptableAddr + 9);
  uint16_t sp = (cpu.memory->at(ptableAddr + 8) << 8) | cpu.memory->at(ptableAddr + 7);
  uint16_t base = (cpu.memory->at(ptableAddr + 12) << 8) | cpu.memory->at(ptableAddr + 11);
  uint16_t baseContent = base + pc;
  uint16_t processNameAddr = (cpu.memory->at(ptableAddr + 17) << 8) | cpu.memory->at(ptableAddr + 16);
  
  cout << "\n----Context Scheduling----" << endl;
  printf("PID   :\t%4d | ",  pid);
  printf("PNAME    : ");

  while(cpu.memory->at(processNameAddr) != (uint8_t) 0){
    cout << cpu.memory->at(processNameAddr);
    processNameAddr++;
  }
  printf("\t| ");

  printf("PC    :\t%4x | ",  pc);
  printf("SP    :\t%4x | ",  sp);
  printf("BASE  :\t%4x | ",  base);
  printf("BASE_CONTENT  :\t%4x\n",  baseContent);
  cout << endl;

  return CYCLE;
}

/*
 * Called to set the quantum time of scheduling
 */
uint64_t GTUOS::setQuantum(CPU8080& cpu){
  uint8_t quantum = cpu.state->b;
  cpu.setQuantum(quantum);
  return 0;
}

/*
 * Caleld when a process wants to exit
 * Removes process from the memory,
 * process table and reduces number of processes
 * by one
 */
uint64_t GTUOS::processExit(CPU8080& cpu){

  uint16_t baseProcessAddr = 0x00500;
  uint16_t processLen = 512;

  uint16_t ptableStart = 0x0d000;
  uint16_t ptableLen = 256;

  uint16_t ptableAddr = ptableStart;
  
  uint16_t currProcessAddr = ((Memory*)(cpu.memory))->getBaseRegister();
  uint16_t tempProcessAddr = currProcessAddr;

  uint16_t schedulerAddr = 0x00040;
  
  int i = 0;
  while(tempProcessAddr != baseProcessAddr){
    tempProcessAddr -=processLen;
    i++;
  }

  while(i > 0){
    ptableAddr += ptableLen;
    i--;
  }

  uint16_t lastProcess = 0x0cffe;
  uint16_t processCount = 0x0cfff;
  
  ((Memory*)(cpu.memory))->setBaseRegister(0);
  memset(&cpu.memory->at(currProcessAddr),0,processLen);
  memset(&cpu.memory->at(ptableAddr),0,ptableLen);

  //cpu.memory->at(lastProcess) = cpu.memory->at(lastProcess) - 1;
  cpu.memory->at(processCount) = cpu.memory->at(processCount) - 1;
  cpu.state->pc = schedulerAddr; //go back to scheduler
  return (CYCLE * 8);
}

/*
 * Loads a new process to the given address 
 **/
uint64_t GTUOS::loadExec(CPU8080& cpu){
  uint16_t fileNameAddr;
  uint16_t processStartAddr;
  
  char* fileName = (char* ) malloc(sizeof(uint8_t) * 64);

  fileNameAddr = ((uint16_t)cpu.state->b << 8) | cpu.state->c;

  int i = 0;
  while(cpu.memory->at(fileNameAddr) != (uint8_t) 0){
    fileName[i] = cpu.memory->at(fileNameAddr);
    fileNameAddr++;
    i++;
  }
  fileName[i] = 0;

  processStartAddr = ((uint16_t)cpu.state->h << 8) | cpu.state->l;
  
  cpu.ReadFileIntoMemoryAt(fileName, processStartAddr);
  return (CYCLE * 10);
}

/*
  Print the contents of register B
*/
uint64_t GTUOS::sysPrintB( CPU8080& cpu){
  //cout << "-";
  cout << (int)cpu.state->b;
  //printf("%d",(int)cpu.state->b);
  return CYCLE;
}
/*
  Print the content of memory pointed by B and C
  Calculate start address first then get the block
*/
uint64_t GTUOS::sysPrintMem( CPU8080& cpu){
  uint16_t fileNameAddr;
  fileNameAddr = ((uint16_t)cpu.state->b << 8) | cpu.state->c;
  cout << (int)cpu.memory->at(fileNameAddr);
  //printf("%02x\n",(int)cpu.memory->at(fileNameAddr));
  return CYCLE;
}

/*
  Read an integer and put it to B
*/
uint64_t GTUOS::sysReadB( CPU8080& cpu){
  uint16_t num;
  cin >> num;
  cpu.state->b = num;
    
  return CYCLE;
}

/*
  Read an integer and put it to memory address pointed
  by B and C
*/
uint64_t GTUOS::sysReadMem( CPU8080& cpu){
    int readVal;
    uint16_t realValue;

    cin >> readVal;
    realValue = (uint16_t) readVal;

    if (readVal < 0 || readVal > 65535){
      cout << "Error! Bigger than 16 bits not accepted" << endl;
    }else{
      uint8_t leastSign = (uint8_t) realValue;
      uint8_t mostSign = (uint8_t) (realValue >> 8);
      cpu.state->c = leastSign;
      cpu.state->b = mostSign;
    }
    return CYCLE;
}

/*
  Print the null terminated string
  whose start address is stored cin B and C
*/
uint64_t GTUOS::sysPrintStr( CPU8080& cpu){
  uint16_t fileNameAddr;
  fileNameAddr = ((uint16_t)cpu.state->b << 8) | cpu.state->c;
  
  while(cpu.memory->at(fileNameAddr) != (uint8_t) 0){
    cout << cpu.memory->at(fileNameAddr);
    fileNameAddr++;
  }
  return CYCLE;
}
/*
  Read string and put it to memory address
  pointed by B and C
*/
uint64_t GTUOS::sysReadStr( CPU8080& cpu){
  uint16_t fileNameAddr;
  string str;
  cin >> str;
  fileNameAddr = (((uint16_t)cpu.state->b) << 8) | cpu.state->c;
  for(int i = 0 ; i < (signed) str.length() ; ++i){
    cpu.memory->at(fileNameAddr) = str[i];
    fileNameAddr++;
  }
  cpu.memory->at(fileNameAddr) = (uint8_t)'\0'; 
  return CYCLE;
}
