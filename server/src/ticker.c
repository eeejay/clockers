#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include <math.h>
#include "spin.h"

#ifdef DEBUG
#define DEBUG_PRINT(...) do{ printf( __VA_ARGS__ ); } while( false )
#else
#define DEBUG_PRINT(...) do{ } while ( false )
#endif

bool goToEnd;
int tickBacklog;

void tick(int signum) {
  signal(SIGUSR1, tick);
}

void tickWhileGoToEnd(int signum) {
  tickBacklog++;
  signal(SIGUSR1, tickWhileGoToEnd);
}

void tickend(int signum) {
  goToEnd = true;
  signal(SIGUSR2, tickend);
}

int main (int argc, char* argv[]) {
  int pins[4];
  int inpin;
  float tickSize;
  float rpm;
  bool limitReached = false;
  goToEnd = false;
  tickBacklog = 0;

  signal(SIGUSR1, tick);
  signal(SIGUSR2, tickend);

  setbuf(stdout, NULL);

  if (argc < 6) {
    printf("Usage: ticker <pin1> <pin2> <pin3> <pin4> <limitpin> <rpm> <ticksize>\n");
    _exit(1);
  }

  for (int i = 1; i < 5; i++) {
    sscanf (argv[i],"%d",&pins[i-1]);
  }
  sscanf (argv[5],"%d",&inpin);
  sscanf (argv[6],"%f",&rpm);
  sscanf (argv[7],"%f",&tickSize);

  setup();

  while (1) {
    pause();

    if (goToEnd) {
      if (!limitReached) {
        signal(SIGUSR1, tickWhileGoToEnd); // redirect signal so we can finish this.
        int s = spinWithRpm(pins, inpin, 0, rpm, NULL);
        DEBUG_PRINT("Steps took to end.. %d\n", s);
        while (tickBacklog) {
          float stepsToTake = tickBacklog*tickSize;
          DEBUG_PRINT("tickBacklog=%d stepsToTake=%f\n", tickBacklog, stepsToTake);
          tickBacklog = 0;
          spinWithRpm(pins, inpin, stepsToTake, rpm, NULL);
        }
        tickBacklog = 0;
        signal(SIGUSR1, tick);
      }
      goToEnd = false;
      limitReached = false;
    } else {
      if (!limitReached) {
        int s = spinWithRpm(pins, inpin, tickSize, rpm, &limitReached);
        DEBUG_PRINT("Steps took: %d\n", s);
        if (limitReached) {
          DEBUG_PRINT("limit reached!\n");
        }
      }
    }
  }

  return 0 ;
}
