#include <stdlib.h>
#include <stdio.h> 
#include <string.h> 
#include <time.h>
clock_t clock();

void initrand(unsigned int seed)
{
	
//clock_t clock();
//printf("");
    srand((unsigned int)(seed));
} 

int randint(int max)
{
    return (rand()%(max));
}

void main (int argc, char *argv[])
{

initrand(atoi(argv[1]));
 int i = randint(2960000);
fprintf(stdout,"%d\n", i );
}
