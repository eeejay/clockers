#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include "spin.h"

#ifdef DEBUG
#define DEBUG_PRINT(...) do{ printf( __VA_ARGS__ ); } while( false )
#else
#define DEBUG_PRINT(...) do{ } while ( false )
#endif

struct timeval tickTime = { 0 };

void tick(int signum) {
  DEBUG_PRINT("swiss tick!\n");
  signal(SIGUSR1, tick);
}

int timedifference_microsec(struct timeval t0, struct timeval t1)
{
  return (t1.tv_sec - t0.tv_sec) * 1000000 + (t1.tv_usec - t0.tv_usec);
}

int main (int argc, char* argv[]) {
  int pins[4];
  int inpin;
  float pausetime;

  setbuf(stdout, NULL);

  signal(SIGUSR1, tick);

  if (argc < 6) {
    printf("Usage: swiss <pin1> <pin2> <pin3> <pin4> <limitpin> <pausetime>\n");
    _exit(1);
  }

  for (int i = 1; i < 5; i++) {
    sscanf (argv[i],"%d",&pins[i-1]);
  }
  sscanf (argv[5],"%d",&inpin);
  sscanf (argv[6],"%f",&pausetime);

  setup();
  printf("swiss! Tick!\n");

  while (1) {
    spinWithRpm(pins, inpin, 0, 60.0f/(60.0f-pausetime)*GEAR_RATIO, NULL);
    printf("swiss reached top\n");
    pause();
  }

  return 0 ;
}
