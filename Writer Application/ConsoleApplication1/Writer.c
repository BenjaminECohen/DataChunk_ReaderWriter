
#define _CRT_SECURE_NO_DEPRECATE
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#define CHAR_BUFF_SIZE (100)
#define MAX_SECTION_PART_SIZE (1000)
#define SECTION_SIZE (7)


int numByteMin;
int numByteMax;
int numWordMin;
int numWordMax;
int numLongMin;
int numLongMax;

int bValMin;
int bValMax;
int wValMin;
int wValMax;
int lValMin;
int lValMax;

char* GetSubstring(char * string, int startIndex, int endIndex)
{
    char substring[CHAR_BUFF_SIZE];
    int j = 0;

    for (int i = startIndex; i < endIndex && (int)string[i] != 0 && (int)string[i] != -52; i++)
    {

        substring[j++] = string[i];

    }
    substring[j] = 0;    
    return substring;

}

int GetIndexOf(char* string, char c)
{
    int i = 0;
    while ((int)string[i] != 0 && (int)string[i] != -52)
    {
        if (string[i] == c)
        {
            return i;
        }
        i++;
    }
    return i;
}

int CheckSize(int num)
{
    if (num < 0)
    {
        printf("%d is too small, constraining to 0\n", num);
        return 0;
    }
    if (num > MAX_SECTION_PART_SIZE)
    {
        printf("%d is too large, constraining to max subsection size of %d\n", num, MAX_SECTION_PART_SIZE);
        return MAX_SECTION_PART_SIZE;
    }
    return num;
}

int CheckSign(int num)
{
    if (num < 0)
    {
        printf("Negative value for Val range detected, setting %d to positive\n", num);
        return -1 * num;
    }
    return num;
}

_Bool ReadConfigurationFile(FILE* file)
{
    char configBuff[CHAR_BUFF_SIZE];
    char* remainder;

    int index = 0;

    char* substring[CHAR_BUFF_SIZE];

    char* name[CHAR_BUFF_SIZE];

    int min = 0;
    int max = 0;

    const char delimiter = ':';
    

    for (int i = 0; i < 6; i++)
    {
        fscanf(file, "%s", configBuff);
        //printf("%s\n", configBuff);

        memset(substring, '\0', sizeof(substring));
        memset(name, '\0', sizeof(name));

        index = GetIndexOf(configBuff, delimiter);
        strncpy(name, configBuff, index);
        remainder = strchr(configBuff, delimiter);
        //printf("Name %s\n", name);
        
        index = GetIndexOf(++remainder, delimiter);
        min = atoi(strncpy(substring, remainder, index));
        remainder = strchr(remainder, delimiter);
        //printf("Min is %d\n", min);
        

        max = atoi(strcpy(substring, ++remainder));
        //printf("Max will be %s\n", remainder);

        if (strcmp(name, "NUM_BYTES") == 0)
        {
            min = CheckSize(min);
            numByteMin = min;
            
            max = CheckSize(max);
            numByteMax = max;
        }
        else if (strcmp(name, "NUM_SHORTS") == 0)
        {
            min = CheckSize(min);
            numWordMin = min;
            
            max = CheckSize(max);
            numWordMax = max;
        }
        else if (strcmp(name, "NUM_LONGS") == 0)
        {
            min = CheckSize(min);
            numLongMin = min;

            max = CheckSize(max);
            numLongMax = max;
        }
        else if (strcmp(name, "BYTEVAL") == 0)
        {
            min = CheckSign(min);
            bValMin = min;

            max = CheckSign(max);
            bValMax = max;
        }
        else if (strcmp(name, "SHORTVAL") == 0)
        {
            min = CheckSign(min);
            wValMin = min;

            max = CheckSign(max);
            wValMax = max;
        }
        else if (strcmp(name, "LONGVAL") == 0)
        {
            min = CheckSign(min);
            lValMin = min;

            max = CheckSign(max);
            lValMax = max;
        }
        else
        {
            printf("DEFAULT, SHOULDNT BE HERE\n");
            return 1;
        }

    }

    return 0;
    

}


int main()
{

    FILE *file = fopen("Configuration.txt", "r");
    
    srand(time(NULL));

    
    char string[255];
    printf("Reading Config File\n");
    fscanf(file, "%s", string);
    //printf("%s\n", string);

    const char delimiter = ':';

    char* fileType;
    fileType = strchr(string, delimiter);

    if (strcmp(++fileType, "WriterConfig") != 0)
    {
        printf("Config file is not of Type:WriterConfig. Please use a correct config file.");
        return 0;
    }

    //Read the configuration file
    if (ReadConfigurationFile(file) != 0)
    {
        printf("Configuration File Parse Failed: Check Config File Formatting.");
        return 0;
    }

    fclose(file);

    //Get Player Input for how many sections they want
    char* userInput[10];
    printf("Please enter the number of sections you want: \n");
    gets(userInput);
    int sectionCount = atoi(userInput);

    if (sectionCount >= 50)
    {
        sectionCount = 49;
    }
    if (sectionCount <= 0)
    {
        sectionCount = 1;
    }

    printf("User Inputted %s\n", userInput);
    printf("Sections to generate %d\n", sectionCount);

    FILE* binFile = fopen("output.bin", "wb"); //Output stream
    fpos_t startOfFile;
    fgetpos(binFile, &startOfFile);

    FILE* statFile = fopen("statistics.txt", "w");

    fprintf(statFile, "%s %d %s\n", "User chose", sectionCount, "sections.");

    //Free up space to section count + 1 (first long holds the number of sections)
    long fileHeader[MAX_SECTION_PART_SIZE];
    

    long fileHeaderSize = sizeof(long) * (sectionCount + 1); //ActualHeader size is section count longs + # of section long

    fwrite(fileHeader, sizeof(long), sectionCount + 1, binFile);
    //printf("Tell: We are at position %d after putting %d elements of %d bytes long\n", ftell(binFile), sectionCount + 1, sizeof(long));

    fileHeader[0] = sectionCount;   //Get number of sections in file
    fileHeader[1] = fileHeaderSize; //Start of section 1 is at end of file header

    //printf("File Header: Section %d is at an offset of %d\n", 1, ftell(binFile));

    int size;

    //Generate Sections
    for (int i = 0; i < sectionCount; i++)
    {

        unsigned long avg = 0;
        
        fileHeader[i + 1] = ftell(binFile); //Set offset of the current section
        //printf("File Header: Section %d is at an offset of %d\n", i + 1, ftell(binFile));

        fprintf(statFile, "%s %d\n", "Section", i + 1);

        //Create Section Header
        unsigned short sectionHeader[SECTION_SIZE];

        

        sectionHeader[0] = (short)i + 1;                       //Save section Number

        sectionHeader[1] = sizeof(sectionHeader); //Bytes start at offset of sectionHeaderSize

        //Generate Bytes
        short byteSize = (rand() % (numByteMax - numByteMin + 1)) + numByteMin; //Get number of bytes to generate in the section     
        

        unsigned char sectionBytes[MAX_SECTION_PART_SIZE];
        for (int j = 0; j < byteSize; j++)
        {
            sectionBytes[j] = (rand() % (bValMax - bValMin + 1)) + bValMin;
            avg += sectionBytes[j];
        }
        //If size is odd, add +1 so we have a small offset for future words and longs (no odd register)
        if (byteSize % 2 != 0)
        { 
            sectionBytes[byteSize] = (char) 0; //Set a char of 0
        }
        sectionHeader[2] = byteSize;

        fprintf(statFile, "%d %s %.2f\n", byteSize, "bytes, average value ", (float)avg / (float)byteSize);
        avg = 0;

        //Prepare offset for shorts subsection
        sectionHeader[3] = (short)(byteSize + (byteSize % 2) + sectionHeader[1]);  //Offset of shorts is Byte subsection offset + byte subsection size + remainder (buffer)
        

        //Generate Shorts
        short shortSize = (rand() % (numWordMax - numWordMin + 1)) + numWordMin;
        unsigned short sectionShorts[MAX_SECTION_PART_SIZE];
        for (int j = 0; j < shortSize; j++)
        {
            sectionShorts[j] = (rand() % (wValMax - wValMin + 1)) + wValMin;
            avg += sectionShorts[j];
        }
        sectionHeader[4] = shortSize;
        fprintf(statFile, "%d %s %.2f\n", shortSize, "shorts, average value ", (float)avg / (float)shortSize);
        avg = 0;

        sectionHeader[5] = (short)((shortSize * sizeof(short)) + sectionHeader[3]);  //Offset of short subsection offset + short subsection size (times size of word)

        //Generate Longs
        short longSize = (rand() % (numLongMax - numLongMin + 1)) + numLongMin;
        unsigned long sectionLongs[MAX_SECTION_PART_SIZE];
        for (int j = 0; j < longSize; j++)
        {
            sectionLongs[j] = (rand() % (lValMax - lValMin + 1)) + lValMin;
            avg += sectionLongs[j];
        }
        sectionHeader[6] = longSize;
        fprintf(statFile, "%d %s %.2f\n", longSize, "longs, average value ", (float)avg / (float)longSize);
        

        fwrite(sectionHeader, sizeof(short), SECTION_SIZE, binFile);
        //printf("Byte Offset: We are at position %d after putting (Header) %d elements of %d bytes long\n", ftell(binFile), SECTION_SIZE, sizeof(short));

        fwrite(sectionBytes, sizeof(char), byteSize + (byteSize % 2), binFile);
        //printf("Short Offset: We are at position %d after putting (Bytes) %d elements of %d bytes long\n", ftell(binFile), byteSize, sizeof(char));

        fwrite(sectionShorts, sizeof(short), shortSize, binFile);
        //printf("Long Offset: We are at position %d after putting (Shorts) %d elements of %d bytes long\n", ftell(binFile), shortSize, sizeof(short));

        fwrite(sectionLongs, sizeof(long), longSize, binFile);
        //printf("Next Section Offset: We are at position %d after putting (Longs) %d elements of %d bytes long\n", ftell(binFile), longSize, sizeof(long));

        fprintf(statFile, "...\n");

    }

    //Rewrite header to start of file with filled out header
    fsetpos(binFile, &startOfFile);
    printf("Stream now at pos: %d\n", ftell(binFile));
    fwrite(fileHeader, sizeof(long), sectionCount + 1, binFile);

    fclose(binFile);
    



}



